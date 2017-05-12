package Config::Auto;

use strict;
use warnings;

use Carp qw[croak];

use vars qw[$VERSION $DisablePerl $Untaint $Debug];

$VERSION        = '0.44';
$DisablePerl    = 0;
$Untaint        = 0;
$Debug          = 0;

=head1 NAME

Config::Auto - Magical config file parser

=head1 SYNOPSIS

    use Config::Auto;

    ### Not very magical at all.
    $config = Config::Auto::parse("myprogram.conf", format => "colon");

    ### Considerably more magical.
    $config = Config::Auto::parse("myprogram.conf");

    ### Highly magical.
    $config = Config::Auto::parse();

    ### Using the OO interface
    $ca     = Config::Auto->new( source => $text );
    $ca     = Config::Auto->new( source => $fh );
    $ca     = Config::Auto->new( source => $filename );

    $href   = $ca->score;           # compute the score for various formats

    $config = $ca->parse;           # parse the config

    $format = $ca->format;          # detected (or provided) config format
    $str    = $ca->as_string;       # config file stringified
    $fh     = $ca->fh;              # config file handle
    $file   = $ca->file;            # config filename
    $aref   = $ca->data;            # data from your config, split by newlines

=cut


=head1 DESCRIPTION

This module was written after having to write Yet Another Config File Parser
for some variety of colon-separated config. I decided "never again".

Config::Auto aims to be the most C<DWIM> config parser available, by detecting
configuration styles, include paths and even config filenames automagically.

See the L<HOW IT WORKS> section below on implementation details.

=cut

=head1 ACCESSORS

=head2 @formats = Config::Auto->formats

Returns a list of supported formats for your config files. These formats
are also the keys as used by the C<score()> method.

C<Config::Auto> recognizes the following formats:

=over 4

=item * perl    => perl code

=item * colon   => colon separated (e.g., key:value)

=item * space   => space separated (e.g., key value)

=item * equal   => equal separated (e.g., key=value)

=item * bind    => bind style (not available)

=item * irssi   => irssi style (not available)

=item * xml     => xml (via XML::Simple)

=item * ini     => .ini format (via Config::IniFiles)

=item * list    => list (e.g., foo bar baz)

=item * yaml    => yaml (via YAML.pm)

=back

=cut

my %Methods = (
    perl   => \&_eval_perl,
    colon  => \&_colon_sep,
    space  => \&_space_sep,
    equal  => \&_equal_sep,
    bind   => \&_bind_style,
    irssi  => \&_irssi_style,
    ini    => \&_parse_ini,
    list   => \&_return_list,
    yaml   => \&_yaml,
    xml    => \&_parse_xml,
);

sub formats { return keys %Methods }

=head1 METHODS

=head2 $obj = Config::Auto->new( [source => $text|$fh|$filename, path => \@paths, format => FORMAT_NAME] );

Returns a C<Config::Auto> object based on your configs source. This can either be:

=over 4

=item a filehandle

Any opened filehandle, or C<IO::Handle>/C<IO::String> object.

=item a plain text string

Any plain string containing one or more newlines.

=item a filename

Any plain string pointing to a file on disk

=item nothing

A heuristic will be applied to find your config file, based on the name of
your script; C<$0>.

=back

Although C<Config::Auto> is at its most magical when called with no parameters,
its behavior can be controlled explicitly by using one or two arguments.

If a filename is passed as the C<source> argument, the same paths are checked,
but C<Config::Auto> will look for a file with the passed name instead of the
C<$0>-based names.

Supplying the C<path> parameter will add additional directories to the search
paths. The current directory is searched first, then the paths specified with
the path parameter. C<path> can either be a scalar or a reference to an array
of paths to check.

The C<format> parameters forces C<Config::Auto> to interpret the contents of
the configuration file in the given format without trying to guess.

=cut

### generate accessors
{   no strict 'refs';
    for my $meth ( qw[format path source _fh _data _file _score _tmp_fh] ) {
        *$meth = sub {
            my $self        = shift;
            $self->{$meth}  = shift if @_;
            return $self->{$meth};
        };
    }
}

sub new {
    my $class   = shift;
    my %hash    = @_;
    my $self    = bless {}, $class;

    if( my $format = $hash{'format'} ) {

        ### invalid format
        croak "No such format '$format'" unless $Methods{$format};

        $self->format( $format );
    }

    ### set the other values that could be passed
    for my $key ( qw[source path] ) {
        $self->$key( defined $hash{$key} ? $hash{$key} : '' );
    }

    return $self;
}

=head2 $rv = $obj->parse | Config::Auto::parse( [$text|$fh|$filename, path => \@paths, format => FORMAT_NAME] );

Parses the source you provided in the C<new()> call and returns a data
structure representing your configuration file.

You can also call it in a procedural context (C<Config::Auto::parse()>), where
the first argument is the source, and the following arguments are named. This
function is provided for backwards compatiblity with releases prior to 0.29.

=cut

sub parse {
    my $self = shift;

    ### XXX todo: re-implement magic configuration file finding based on $0

    ### procedural invocation, fix to OO
    unless( UNIVERSAL::isa( $self, __PACKAGE__ ) ) {
        $self = __PACKAGE__->new( source => $self, @_ )
                    or croak( "Could not parse '$self' => @_" );
    }

    my $file = $self->file;
    croak "No config file found!"           unless defined $file;
    croak "Config file $file not readable!" unless -e $file;

    ### from Toru Marumoto: Config-Auto return undef if -B $file
    ### <21d48be50604271656n153e6db6m9b059f57548aaa32@mail.gmail.com>
    # If a config file "$file" contains multibyte charactors like japanese,
    # -B returns "true" in old version of perl such as 5.005_003. It seems
    # there is no problem in perl 5.6x or newer.
    ### so check -B and only return only if
    unless( $self->format ) {
        return if $self->file and -B $self->file and $] >= '5.006';

        my $score = $self->score;

        ### no perl?
        delete $score->{perl} if exists $score->{perl} and $DisablePerl;

        ### no formats found
        croak "Unparsable file format!" unless keys %$score;

        ### Clear winner?
        {   my @methods = sort { $score->{$b} <=> $score->{$a} } keys %$score;
            if (@methods > 1) {
                croak "File format unclear! " .
                    join ",", map { "$_ => $score->{$_}"} @methods
                        if $score->{ $methods[0] } == $score->{ $methods[1] };
            }
            $self->format( $methods[0] );

            $self->_debug( "Using the following format for parsing: " . $self->format );
        }
    }

    return $Methods{ $self->format }->($self);
}

=head2 $href = $obj->score;

Takes a look at the contents of your configuration data and produces a
'score' determining which format it most likely contains.

They keys are equal to formats as returned by the C<< Config::Auto->formats >>
and their values are a score between 1 and 100. The format with the highest
score will be used to parse your configuration data, unless you provided the
C<format> option explicitly to the C<new()> method.

=cut

sub score {
    my $self = shift;

    return $self->_score if $self->_score;

    my $data = $self->data;

    return { xml  => 100 }  if $data->[0] =~ /^\s*<\?xml/;
    return { perl => 100 }  if $data->[0] =~ /^#!.*perl/;
    my %score;

    for (@$data) {
        ### it's almost definately YAML if the first line matches this
        $score{yaml} += 20              if /(?:\#|%)    # a #YAML or %YAML
                                            YAML
                                            (?::|\s)    # a YAML: or YAML[space]
                                        /x and $data->[0] eq $_;
        $score{yaml} += 20              if /^---/ and $data->[0] eq $_;
        $score{yaml} += 10              if /^\s+-\s\w+:\s\w+/;

        # Easy to comment out foo=bar syntax
        $score{equal}++                 if /^\s*#\s*\w+\s*=/;
        next if /^\s*#/;

        $score{xml}++                   for /(<\w+.*?>)/g;
        $score{xml}+= 2                 for m|(</\w+.*?>)|g;
        $score{xml}+= 5                 for m|(/>)|g;
        next unless /\S/;

        $score{equal}++, $score{ini}++  if m|^.*=.*$|;
        $score{equal}++, $score{ini}++  if m|^\S+\s+=\s+|;
        $score{colon}++                 if /^[^:]+:[^:=]+/;
        $score{colon}+=2                if /^\s*\w+\s*:[^:]+$/;
        $score{colonequal}+= 3          if /^\s*\w+\s*:=[^:]+$/; # Debian foo.
        $score{perl}+= 10               if /^\s*\$\w+(\{.*?\})*\s*=.*/;
        $score{space}++                 if m|^[^\s:]+\s+\S+$|;

        # mtab, fstab, etc.
        $score{space}++                 if m|^(\S+)\s+(\S+\s*)+|;
        $score{bind}+= 5                if /\s*\S+\s*{$/;
        $score{list}++                  if /^[\w\/\-\+]+$/;
        $score{bind}+= 5                if /^\s*}\s*$/  and exists $score{bind};
        $score{irssi}+= 5               if /^\s*};\s*$/ and exists $score{irssi};
        $score{irssi}+= 10              if /(\s*|^)\w+\s*=\s*{/;
        $score{perl}++                  if /\b([@%\$]\w+)/g;
        $score{perl}+= 2                if /;\s*$/;
        $score{perl}+=10                if /(if|for|while|until|unless)\s*\(/;
        $score{perl}++                  for /([\{\}])/g;
        $score{equal}++, $score{ini}++  if m|^\s*\w+\s*=.*$|;
        $score{ini} += 10               if /^\s*\[[\s\w]+\]\s*$/;
    }

    # Choose between Win INI format and foo = bar
    if (exists $score{ini}) {
        no warnings 'uninitialized';
        $score{ini} > $score{equal}
            ? delete $score{equal}
            : delete $score{ini};
    }

    # Some general sanity checks
    if (exists $score{perl}) {
        $score{perl} /= 2   unless ("@$data" =~ /;/) > 3 or $#$data < 3;
        delete $score{perl} unless ("@$data" =~ /;/);
        delete $score{perl} unless ("@$data" =~ /([\$\@\%]\w+)/);
    }

    if ( $score{equal} && $score{space} && $score{equal} == $score{space} ) {
      $score{equal}++;
    }

    $self->_score( \%score );

    return \%score;
}

=head2 $aref = $obj->data;

Returns an array ref of your configuration data, split by newlines.

=cut

sub data {
    my $self = shift;
    return $self->_data if $self->_data;

    my $src = $self->source;

    ### filehandle
    if( ref $src ) {
        my @data = <$src>;
        $self->_data( \@data );

        seek $src, 0, 0; # reset position!

    ### data
    } elsif ( $src =~ /\n/ ) {
        $self->_data( [ split $/, $src, -1 ] );

    ### filename
    } else {
        my $fh = $self->fh;
        my @data = <$fh>;
        $self->_data( \@data );

        seek $fh, 0, 0; # reset position!
    }

    return $self->_data;
}

=head2 $fh = $obj->fh;

Returns a filehandle, opened for reading, containing your configuration
data. This works even if you provided a plain text string or filename to
parse.

=cut

sub fh {
    my $self = shift;
    return $self->_fh if $self->_fh;

    my $src = $self->source;

    ### filehandle
    if( ref $src ) {
        $self->_fh( $src );

    ### data
    } elsif ( $src =~ /\n/ ) {
        require IO::String;

        my $fh = IO::String->new;
        print $fh $src;
        $fh->setpos(0);

        $self->_fh( $fh );

    } else {
        my $fh;
        my $file = $self->file;

        if( open $fh, $file ) {
            $self->_fh( $fh );
        } else {
            $self->_debug( "Could not open '$file': $!" );
            return;
        }
    }

    return $self->_fh;
}

=head2 $filename = $obj->file;

Returns a filename containing your configuration data. This works even
if you provided a plaintext string or filehandle to parse. In that case,
a temporary file will be written holding your configuration data.

=cut

sub file {
    my $self = shift;
    return $self->_file if $self->_file;

    my $src = $self->source;

    ### filehandle or datastream, no file attached =/
    ### so write a temp file
    if( ref $src or $src =~ /\n/ ) {

        ### require only when needed
        require File::Temp;

        my $tmp = File::Temp->new;
        $tmp->print( ref $src ? <$src> : $src );
        $tmp->close;                    # write to disk

        $self->_tmp_fh( $tmp );         # so it won't get destroyed
        $self->_file( $tmp->filename );

        seek $src, 0, 0 if ref $src;    # reset position!

    } else {
        my $file = $self->_find_file( $src, $self->path ) or return;

        $self->_file( $file );
    }

    return $self->_file;
}

=head2 $str = $obj->as_string;

Returns a string representation of your configuration data.

=cut

sub as_string {
    my $self = shift;
    my $data = $self->data;

    return join $/, @$data;
}

sub _find_file {
    my ($self, $file, $path) = @_;


    ### moved here so they are only loaded when looking for a file
    ### all to keep memory usage down.
    {   require File::Spec::Functions;
        File::Spec::Functions->import('catfile');

        require File::Basename;
        File::Basename->import(qw[dirname basename]);
    }

    my $bindir = dirname($0);
    my $whoami = basename($0);

    $whoami =~ s/\.(pl|t)$//;

    my @filenames = $file ||
                     ("${whoami}config", "${whoami}.config",
                      "${whoami}rc",    ".${whoami}rc");

    my $try;
    for my $name (@filenames) {

        return $name        if -e $name;
        return $try         if ( $try = $self->_chkpaths($path, $name) ) and -e $try;
        return $try         if -e ( $try = catfile($bindir,     $name) );
        return $try         if $ENV{HOME} && -e ( $try = catfile($ENV{HOME},  $name) );
        return "/etc/$name" if -e "/etc/$name";
        return "/usr/local/etc/$name"
                            if -e "/usr/local/etc/$name";
    }

    $self->_debug( "Could not find file for '". $self->source ."'" );

    return;
}

sub _chkpaths {
    my ($self, $paths, $filename) = @_;

    ### no paths? no point in checking
    return unless defined $paths;

    my $file;
    for my $path ( ref($paths) eq 'ARRAY' ? @$paths : $paths ) {
        return $file if -e ($file = catfile($path, $filename));
    }

    return;
}

sub _eval_perl   {

    my $self = shift;
    my $str  = $self->as_string;

    ($str) = $str =~ m/^(.*)$/s if $Untaint;

    my $cfg = eval "$str";
    croak __PACKAGE__ . " couldn't parse perl data: $@" if $@;
    return $cfg;
}

sub _parse_xml   {
    my $self = shift;

    ### Check if XML::Simple is already loaded
    unless ( exists $INC{'XML/Simple.pm'} ) {
        ### make sure we give good diagnostics when XML::Simple is not
        ### available, but required to parse a config
        eval { require XML::Simple; XML::Simple->import; 1 };
        croak "XML::Simple not available. Can not parse " .
              $self->as_string . "\nError: $@\n" if $@;
    }

    return XML::Simple::XMLin( $self->as_string );
}

sub _parse_ini   {
    my $self = shift;

    ### Check if Config::IniFiles is already loaded
    unless ( exists $INC{'Config/IniFiles.pm'} ) {
        ### make sure we give good diagnostics when XML::Simple is not
        ### available, but required to parse a config
        eval { require Config::IniFiles; Config::IniFiles->import; 1 };
        croak "Config::IniFiles not available. Can not parse " .
              $self->as_string . "\nError: $@\n" if $@;
    }

    tie my %ini, 'Config::IniFiles', ( -file => $self->file );
    return \%ini;
}

sub _return_list {
    my $self = shift;

    ### there shouldn't be any trailing newlines or empty entries here
    return [ grep { length } map { chomp; $_ } @{ $self->data } ];
}

### Changed to YAML::Any which selects the fastest YAML parser available
### (req YAML 0.67)
sub _yaml {
    my $self = shift;
    require YAML::Any;

    return YAML::Any::Load( $self->as_string );
}

sub _bind_style  { croak "BIND8-style config not supported in this release" }
sub _irssi_style { croak "irssi-style config not supported in this release" }

# BUG: These functions are too similar. How can they be unified?

sub _colon_sep {
    my $self = shift;
    my $fh   = $self->fh;

    my %config;
    local $_;
    while (<$fh>) {
        next if /^\s*#/;
        /^\s*(.*?)\s*:\s*(.*)/ or next;
        my ($k, $v) = ($1, $2);
        my @v;
        if ($v =~ /:/) {
            @v =  split /:/, $v;
        } elsif ($v =~ /, /) {
            @v = split /\s*,\s*/, $v;
        } elsif ($v =~ / /) {
            @v = split /\s+/, $v;
        } elsif ($v =~ /,/) { # Order is important
            @v = split /\s*,\s*/, $v;
        } else {
            @v = $v;
        }
        $self->_check_hash_and_assign(\%config, $k, @v);
    }
    return \%config;
}

sub _check_hash_and_assign {
    my $self = shift;

    my ($c, $k, @v) = @_;
    if (exists $c->{$k} and !ref $c->{$k}) {
        $c->{$k} = [$c->{$k}];
    }

    if (grep /=/, @v) { # Bugger, it's really a hash
        for (@v) {
            my ($subkey, $subvalue);

            ### If the array element has an equal sign in it...
            if (/(.*)=(.*)/) {
                ($subkey, $subvalue) = ($1,$2);

            ###...otherwise, if the array element does not contain an equals sign:
            } else {
                $subkey     = $_;
                $subvalue   = 1;
            }

            if (exists $c->{$k} and ref $c->{$k} ne "HASH") {
                # Can we find a hash in here?
                my $h=undef;
                for (@{$c->{$k}}) {
                    last if ref ($h = $_) eq "hash";
                }
                if ($h) { $h->{$subkey} = $subvalue; }
                else { push @{$c->{$k}}, { $subkey => $subvalue } }
            } else {
                $c->{$k}{$subkey} = $subvalue;
            }
        }
    } elsif (@v == 1) {
        if (exists $c->{$k}) {
            if (ref $c->{$k} eq "HASH") { $c->{$k}{$v[0]} = 1; }
            else {push @{$c->{$k}}, @v}
        } else { $c->{$k} = $v[0]; }
    } else {
        if (exists $c->{$k}) {
            if (ref $c->{$k} eq "HASH") { $c->{$k}{$_} = 1 for @v }
            else {push @{$c->{$k}}, @v }
        }
        else { $c->{$k} = [@v]; }
    }
}

{   ### only load Text::ParseWords once;
    my $loaded_tp;

    sub _equal_sep {
        my $self = shift;
        my $fh   = $self->fh;

        my %config;
        local $_;
        while ( <$fh>) {
            next if     /^\s*#/;
            next unless /^\s*(.*?)\s*=\s*(.*?)\s*$/;

            my ($k, $v) = ($1, $2);

            ### multiple enries, but no shell tokens?
            if ($v=~ /,/ and $v !~ /(["']).*?,.*?\1/) {
                $config{$k} = [ split /\s*,\s*/, $v ];
            } elsif ($v =~ /\s/) { # XXX: Foo = "Bar baz"

                ### only load once
                require Text::ParseWords unless $loaded_tp++;

                $config{$k} = [ Text::ParseWords::shellwords($v) ];

            } else {
                $config{$k} = $v;
            }
        }

        return \%config;
    }

    sub _space_sep {
        my $self = shift;
        my $fh   = $self->fh;

        my %config;
        local $_;
        while (<$fh>) {
            next if     /^\s*#/;
            next unless /\s*(\S+)\s+(.*)/;
            my ($k, $v) = ($1, $2);
            my @v;

            ### multiple enries, but no shell tokens?
            if ($v=~ /,/ and $v !~ /(["']).*?,.*?\1/) {
                @v = split /\s*,\s*/, $v;
            } elsif ($v =~ /\s/) { # XXX: Foo = "Bar baz"

                ### only load once
                require Text::ParseWords unless $loaded_tp++;

                @v = Text::ParseWords::shellwords($v);

            } else {
                @v = $v;
            }
            $self->_check_hash_and_assign(\%config, $k, @v);
        }
        return \%config;

    }
}
sub _debug {
    my $self = shift;
    my $msg  = shift or return;

    Carp::confess( __PACKAGE__ . $msg ) if $Debug;
}

1;


__END__

=head1 GLOBAL VARIABLES

=head3 $DisablePerl

Set this variable to true if you do not wish to C<eval> perl style configuration
files.

Default is C<false>

=head3 $Untaint

Set this variable to true if you automatically want to untaint values obtained
from a perl style configuration. See L<perldoc perlsec> for details on tainting.

Default is C<false>

=head3 $Debug

Set this variable to true to get extra debug information from C<Config::Auto>
when finding and/or parsing config files fails.

Default is C<false>

=head1 HOW IT WORKS

When you call C<< Config::Auto->new >> or C<Config::Auto::parse> with no
arguments, we first look at C<$0> to determine the program's name. Let's
assume that's C<snerk>. We look for the following files:

    snerkconfig
    ~/snerkconfig
    /etc/snerkconfig
    /usr/local/etc/snerkconfig

    snerk.config
    ~/snerk.config
    /etc/snerk.config
    /usr/local/etc/snerk.config

    snerkrc
    ~/snerkrc
    /etc/snerkrc
    /usr/local/etc/snerkrc

    .snerkrc
    ~/.snerkrc
    /etc/.snerkrc
    /usr/local/etc/.snerkrc

Additional search paths can be specified with the C<path> option.

We take the first one we find, and examine it to determine what format
it's in. The algorithm used is a heuristic "which is a fancy way of
saying that it doesn't work." (Mark Dominus.) We know about colon
separated, space separated, equals separated, XML, Perl code, Windows
INI, BIND9 and irssi style config files. If it chooses the wrong one,
you can force it with the C<format> option.

If you don't want it ever to detect and execute config files which are made
up of Perl code, set C<$Config::Auto::DisablePerl = 1>.

When using the perl format, your configuration file will be eval'd. This will
cause taint errors. To avoid these warnings, set C<$Config::Auto::Untaint = 1>.
This setting will not untaint the data in your configuration file and should only
be used if you trust the source of the filename.

Then the file is parsed and a data structure is returned. Since we're
working magic, we have to do the best we can under the circumstances -
"You rush a miracle man, you get rotten miracles." (Miracle Max) So
there are no guarantees about the structure that's returned. If you have
a fairly regular config file format, you'll get a regular data
structure back. If your config file is confusing, so will the return
structure be. Isn't life tragic?

=head1 EXAMPLES

Here's what we make of some common Unix config files:

F</etc/resolv.conf>:

    $VAR1 = {
        'nameserver' => [ '163.1.2.1', '129.67.1.1', '129.67.1.180' ],
        'search' => [ 'oucs.ox.ac.uk', 'ox.ac.uk' ]
    };

F</etc/passwd>:

    $VAR1 = {
        'root' => [ 'x', '0', '0', 'root', '/root', '/bin/bash' ],
        ...
    };

F</etc/gpm.conf>:

    $VAR1 = {
        'append' => '""',
        'responsiveness' => '',
        'device' => '/dev/psaux',
        'type' => 'ps2',
        'repeat_type' => 'ms3'
    };

F</etc/nsswitch.conf>:

    $VAR1 = {
        'netgroup' => 'nis',
        'passwd' => 'compat',
        'hosts' => [ 'files', 'dns' ],
        ...
    };

=cut

=head1 MEMORY USAGE

This module is as light as possible on memory, only using modules when they
are absolutely needed for configuration file parsing.

=head1 TROUBLESHOOTING

=over 4

=item When using a Perl config file, the configuration is borked

Give C<Config::Auto> more hints (e.g., add #!/usr/bin/perl to beginning of
file) or indicate the format in the C<new>/C<parse()> command.

=back

=head1 TODO

BIND9 and irssi file format parsers currently don't exist. It would be
good to add support for C<mutt> and C<vim> style C<set>-based RCs.

=head1 BUG REPORTS

Please report bugs or other issues to E<lt>bug-config-auto@rt.cpan.orgE<gt>.

=head1 AUTHOR

Versions 0.04 and higher of this module by Jos Boumans E<lt>kane@cpan.orgE<gt>.

This module originally by Simon Cozens.

=head1 COPYRIGHT

This library is free software; you may redistribute and/or modify it
under the same terms as Perl itself.

=cut
