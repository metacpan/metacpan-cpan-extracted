package Config::Extend::MySQL;
use 5.006;   # read the CAVEATS if you really want a version that works on 5.5
use strict;
use warnings;
use Carp;
use File::Basename          qw(dirname);
use File::Spec::Functions   qw(catfile rel2abs);
use File::Read;
use UNIVERSAL::require;


{
    no strict "vars";
    $VERSION = '0.05';
}

use constant USE_IO_STRING => $] <= 5.008;

my %skip;


=head1 NAME

Config::Extend::MySQL - Extend your favourite .INI parser module to read MySQL configuration file

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

    use Config::Extend::MySQL;

    # read MySQL config using Config::IniFiles
    my $config = Config::Extend::MySQL->new({ from => $file, using => "Config::IniFiles" });

    # read MySQL config using Config::Tiny
    my $config = Config::Extend::MySQL->new({ from => $file, using => "Config::Tiny" });

    # use the resulting object as you usually do
    ...


=head1 DESCRIPTION

This module extends other C<Config::> modules so they can read MySQL
configuration files. It works by slurping and preprocessing the files
before letting your favourite C<Config::> module parse the result.

Currently supported modules are C<Config::IniFiles>, C<Config::INI::Reader> 
and C<Config::Tiny>.

=head2 Rationale

This module was written out of a need of reading MySQL configuration
files from random machines. At first, the author thought they were just
classical C<.INI> files, but soon discovered that they include additional
features like C<!include> and C<!includedir>, and bare boolean options,
which without surprise make most common modules choke or die. 

Hence this module which simply slurps all the files, recursing though the
C<!include> and C<!includedir> directives, inlining their content in 
memory, and transforms the bare boolean options into explicitly assigned 
options. 

As to why this module extends other modules instead of being on its own,
it's because the author was too lazy to think of yet another API and
preferred to use the modules he already know. And given he use several
of them, depending on the context, it was just as easy to avoid being
too thighly coupled to a particular module.


=head1 METHODS

=head2 new()

Create and return an object

B<Usage>

    my $config = Config::Extend::MySQL->new({ from => $file, using => $module });

B<Options>

=over

=item *

C<from> - the path to the main MySQL configuration file

=item *

C<using> - the module name to use as backend for parsing the configuration file

=back

B<Examples>

    # read MySQL config using Config::IniFiles
    my $config = Config::Extend::MySQL->new({ from => $file, using => "Config::IniFiles" });
    # $config ISA Config::Extend::MySQL, ISA Config::IniFiles

    # read MySQL config using Config::Tiny
    my $config = Config::Extend::MySQL->new({ from => $file, using => "Config::Tiny" });
    # $config ISA Config::Extend::MySQL, ISA Config::Tiny

=cut

sub new {
    my ($class, $args) = @_;

    croak "error: Arguments must be given as a hash reference"
        unless ref $args eq "HASH";
    croak "error: Missing required argument 'from'"
        unless exists $args->{from};
    croak "error: Empty argument 'from'"
        unless defined $args->{from} and length $args->{from};

    # check that the file exists and contains something
    my $file = $args->{from};
    croak "fatal: No such file '$file'" unless -f $file;
    carp "warning: File '$file' is empty" and return if -s _ == 0;

    # read the file and resolve the MySQL-isms
    my $content = __read_config(file => $file);

    my $fh = undef;
    if (USE_IO_STRING) {
        require IO::String;
        $fh = IO::String->new(\$content);
    }
    else {
        open($fh, "<", \$content)
            or croak "fatal: Can't read in-memory buffer: $!";
    }

    # create the object using the given Config:: module
    my $backend = defined $args->{using} ? $args->{using} : "Config::Tiny";
    $backend->require or croak "fatal: Can't load module $args->{using}: $@";
    @Config::Extend::MySQL::ISA = ($backend);
    my $self = __new_from($backend, $fh, \$content)
        or croak "fatal: Backend module failed to parse '$file'";
    bless $self, $class;

    # store the names to skip when reading directories
    my @skip_names = qw(. .. CVS);
    @skip{@skip_names} = (1) x @skip_names;

    return $self
}


sub __new_from {
    my ($backend, $fh, $content_r) = @_;

    if ($backend eq "Config::IniFiles") {
        local $SIG{__WARN__} = sub {}; # avoid a warning from stat() on this $fh
        local *IO::String::FILENO = sub { -1 };
        return Config::IniFiles->new(-file => $fh)
    }
    elsif ($backend eq "Config::Format::Ini") {
        local $SIG{__WARN__} = sub {}; # avoid "slurp redefined" warning
        local *Config::Format::Ini::slurp = sub { return ${$_[0]} };
        return Config::Format::Ini::read_ini($content_r)
    }
    elsif ($backend eq "Config::Simple") {
        # can't get Config::Simple to play nicely because it want to 
        # seek() and flock() the filehandle. seek() works on in-memory
        # filehandles, but flock() doesn't, and can't be faked/replaced

        #my $obj = Config::Simple->new(syntax => "ini");
        #$obj->{_DATA} = $obj->parse_ini_file($fh);
        #return $obj

        return Config::Simple->new($fh)
    }
    elsif ($backend eq "Config::Tiny" or $backend eq "Config::INI::Reader") {
        return $backend->read_string($$content_r)
    }
}


sub __read_config {
    my ($what, $path) = @_;
    my $content = "";
    my $opts = {}; #{ err_mode => "quiet" };

    if ($what eq "file") {
        my $base_dir = dirname($path);
        $content = read_file($opts, $path);

        # handle single param (without value)
        $content =~ s{^ \s* (\w+ (?:-\w+)* ) \s* $}{$1 = yes}xgm;

        # handle includes
        $content =~ s{^ \s* !include(dir)? \s+ (.+) \s* $}
                     { __read_config($1 || "file", rel2abs($2, $base_dir)) }xgme;
    }
    elsif ($what eq "dir") {
        opendir(my $dirh, $path) or return "";

        while (my $file = readdir($dirh)) {
            # skip invisible files and directories we shouldn't 
            # recurse into, like ../ or CVS/
            next if $skip{$file} or index($file, ".") == 0;

            my $filepath = catfile($path, $file);

            if (-f $filepath) {
                $content .= __read_config(file => $filepath)
            }
            elsif (-d _) {
                $content .= __read_config(dir => $filepath)
            }
        }

        closedir($dirh);
    }

    return $content
}


=head1 DIAGNOSTICS

=over

=item C<Arguments must be given as a hash reference>

B<(E)> As the message says, the arguments must be given to the 
function or method as a hash reference.

=item C<Backend module failed to parse '%s'>

B<(F)> The backend module was unable to parse the given file. 
See L<"CAVEATS"> for some hints.

=item C<Can't load module %s: %s>

B<(F)> The backend module could not be loaded. 

=item C<Can't read in-memory buffer: %s>

B<(F)> This should not happen.

=item C<Empty argument '%s'>

B<(E)> The given argument was empty, but a value is required.

=item C<File '%s' is empty>

B<(W)> The file is empty.

=item C<Missing required argument '%s'>

B<(E)> You forgot to supply a mandatory argument.

=item C<No such file '%s'">

B<(F)> The given path does not point to an existing file.

=back


=head1 CAVEATS

The different supported modules don't parse C<.INI> files exactly the
same ways, and have different behaviours:

=over

=item *

C<Config::IniFiles> doesn't want to create an object from an empty file.

=item *

C<Config::INI::Reader> by default doesn't allow the pound sign (C<#>)
for beginning comments.

=item *

when assigning the same option twice, C<Config::Tiny> replaces the old 
value with the new one, C<Config::IniFiles> appends it with a newline.

=back

And probably many more.

Also note that in order to keep the code simple, this module wants 
Perl 5.6 or newer. However, a patch to make it work on Perl 5.5.3 is 
included in the distribution (F<patches/patch-for-perl5.5.diff>).


=head1 SEE ALSO

L<Config::IniFiles>

L<Config::INI::Reader>

L<Config::Tiny>


=head1 AUTHOR

SE<eacute>bastien Aperghis-Tramoni, C<< <sebastien at aperghis.net> >>

=head1 BUGS

Please report any bugs or feature requests 
to C<bug-config-extend-mysql at rt.cpan.org>, or through the web interface 
at L<http://rt.cpan.org/Dist/Display.html?Queue=Config-Extend-MySQL>.
I will be notified, and then you'll automatically be notified of 
progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Config::Extend::MySQL


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Dist/Display.html?Queue=Config-Extend-MySQL>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Config-Extend-MySQL>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Config-Extend-MySQL>

=item * Search CPAN

L<http://search.cpan.org/dist/Config-Extend-MySQL>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2008 SE<eacute>bastien Aperghis-Tramoni, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Config::Extend::MySQL
