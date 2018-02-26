# Configuration parser for Glacier                -*- perl -*-
# Copyright (C) 2016, 2017 Sergey Poznyakoff <gray@gnu.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

package App::Glacier::Config;

use strict;
use Carp;
use File::stat;
use Storable qw(retrieve store);
use App::Glacier::Config::Locus;
use Data::Dumper;

require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'sort' => [ qw(NO_SORT SORT_NATURAL SORT_PATH) ] );
our @EXPORT_OK = qw(NO_SORT SORT_NATURAL SORT_PATH);
    
our $VERSION = "1.00";

=head1 NAME

App::Glacier::Config - generalized configuration file parser

=head1 SYNOPSIS

    my $cfg = new App::Glacier::Config($filename, %opts);
    $cfg->parse() or die;

    if ($cfg->isset('core', 'variable')) {
       ...
    }

    my $x = $cfg->get('file', 'locking');

    $cfg->set('file', 'locking', 'true');

    $cfg->unset('file', 'locking');

=head1 DESCRIPTION

=cut

=head2 $cfg = new App::Glacier::Config($filename, %opts);

Creates new configuration object for file B<$filename>.  Valid
options are:

=over 4

=item B<debug> => I<NUM>

Sets debug verbosity level.    

=item B<ci> => B<0> | B<1>

If B<1>, enables case-insensitive keyword matching.  Default is B<0>,
i.e. the keywords are case-sensitive.    

=item B<parameters> => \%hash

Defines the syntax table.  See below for a description of B<%hash>.

=item B<cachefile> => I<FILENAME>

Sets the location of the cache file.  If passed, the parsed configuration
will be stored in binary form in the I<FILENAME>.  Before parsing the
configuration file, the constructor will chech if the cache file exists and
has the same timestamp as the configuration file.  If so, the configuration
will be loaded from the cache (using B<Storable>(3)), avoiding parsing
overhead.  Otherwise, the cached data will be discarded, and the source file
will be parsed as usual.

The destructor will first check if the configuration was updated, and if
so will recreate the cache file prior to destructing the object instance.    

=item B<rw> => B<0> | B<1>

Whether or not the configuration is read-write.  This setting is in effect
only if B<cachefile> is also set.
    
If set to B<0> (the default) any local changes to the configuration (using
B<set> and B<unset> methods), will not be saved to the cache file upon
exiting.  Otherwise, the eventual modifications will be stored in the cache.    
    
=back    

=head3 Syntax hash

The hash passed via the B<parameters> keyword defines the keywords and
sections allowed within a configuration file.  In a simplest case, a
keyword is described as

    name => 1

This means that B<name> is a valid keyword, but does not imply anything
more about it or its value.  A most complex declaration is possible, in
which the value is a hash reference, containing on or more of the following
keywords:

=over 4

=item mandatory => 0 | 1

Whether or not this setting is mandatory.

=item array => 0 | 1

If B<1>, the value of the setting is an array.  Each subsequent occurrence
of the statement appends its value to the end of the array.

=item re => I<regexp>

Defines a regular expression to which must be matched by the value of the
setting, otherwise a syntax error will be reported.

=item select => I<coderef>

Points to a function to be called to decide whether to apply this hash to
a particular configuration setting.  The function is called as

    &{$coderef}($vref, @path)

where $vref is a reference to the setting (use $vref->{-value}, to obtain
the actual value), and @path is its patname.    
    
=item check => I<coderef>

Defines a code which will be called after parsing the statement in order to
verify its value.  The I<coderef> is called as

    $err = &{$coderef}($valref, $prev_value)

where B<$valref> is a reference to its value, and B<$prev_value> is the value
of the previous instance of this setting.  The function must return B<undef>
if the value is OK for that setting.  In that case, it is allowed to modify
the value, referenced by B<$varlref>.  If the value is erroneous, the function
must return a textual error message, which will be printed using B<$cfg->error>.
    
=back    

To define a section, use the B<section> keyword, e.g.:

    core => {
        section => {
            pidfile => {
               mandatory => 1
            },
            verbose => {
               re => qr/^(?:on|off)/i
            }
        }
    }

This says that a section B<[core]> can have two variables: B<pidfile>, which
is mandatory, and B<verbose>, whose value must be B<on>, or B<off> (case-    
insensitive).

To allow for arbitrary keywords, use B<*>.  For example, the following
declares the B<[code]> section, which must have the B<pidfile> setting
and is allowed to have any other settings as well.    
 
    code => {
       section => {
           pidfile => { mandatory => 1 },
           '*' => 1
       }
    }

Everything said above applies to the B<'*'> as well.  E.g. the following
example declares the B<[code]> section, which must have the B<pidfile>
setting and is allowed to have I<subsections> with arbitrary settings.

    code => {
       section => {
           pidfile = { mandatory => 1 },
           '*' => {
               section => {
                   '*' => 1
               }
           }
       }
    }

The special entry

    '*' => '*'

means "any settings and any subsections".

=cut

sub new {
    my $class = shift;
    my $filename = shift;
    local %_ = @_;
    my $self = bless { filename => $filename }, $class;
    my $v;
    my $err;
    
    if (defined($v = delete $_{debug})) {
	$self->{debug} = $v;
    }

    if (defined($v = delete $_{ci})) {
	$self->{ci} = $v;
    }

    if (defined($v = delete $_{parameters})) {
	if (ref($v) eq 'HASH') {
	    $self->{parameters} = $v;
	} else {
	    carp "parameters must refer to a HASH";
	    ++$err;
	}
    }

    if (defined($v = delete $_{cachefile})) {
	$self->{cachefile} = $v;
    }

    if (defined($v = delete $_{cache})) {
	unless (exists($self->{cachefile})) {
	    $v = $self->{filename};
	    $v =~ s/\.(conf|cnf|cfg)$//;
	    unless ($v =~ s#(.+/)?(.+)#$1.$2#) {
		$v = ".$v";
	    }
	    $self->{cachefile} = "$v.cache";
	}
    }
    
    if (defined($v = delete $_{rw})) {
	$self->{rw} = $v;
    }
    
    if (keys(%_)) {
	foreach my $k (keys %_) {
	    carp "unknown parameter $k"
	}
	++$err;
    }
    return undef if $err;
    return $self;
}

sub DESTROY {
    my $self = shift;
    $self->writecache();
}

=head2 $cfg->error($message)

=head2 $cfg->error($message, locus => $loc)

Prints the B<$message> on STDERR.  If <locus> is given, its value must
be a reference to a valid B<App::Glacier::Config::Locus>(3) object.  In that
case, the object will be formatted first, then followed by a ": " and the
B<$message>.    
    
=cut
    
sub error {
    my $self = shift;
    my $err = shift;
    local %_ = @_;
    $err = $_{locus}->format($err) if exists $_{locus};
    print STDERR "$err\n";
}

=head2 $cfg->debug($lev, @msg)

If B<$lev> is greater than or equal to the B<debug> value used when
creating B<$cfg>, outputs on standard error the strings from @msg,
separating them with a single space character.

Otherwise, does nothing.    

=cut    

sub debug {
    my $self = shift;
    my $lev = shift;
    return unless $self->{debug} >= $lev;
    $self->error("DEBUG: " . join(' ', @_));
}

sub writecache {
    my $self = shift;
    return unless exists $self->{cachefile};
    return unless exists $self->{conf};
    return unless $self->{updated};
    $self->debug(1, "storing cache file $self->{cachefile}");
    store $self->{conf}, $self->{cachefile};
}

sub parse_section {
    my ($self, $conf, $input, $locus) = @_;
    my $ref = $conf;
    my $quote;
    my $kw = $self->{parameters} if exists $self->{parameters};
    while ($input ne '') {
	my $name;
	if (!defined($quote)) {
	    if ($input =~ /^"(.*)/) {
		$quote = '';
		$input = $1;
	    } elsif ($input =~ /^(.+?)(?:\s+|")(.*)/) {
		$name = $1;
		$input = $2;
	    } else {
		$name = $input;
		$input = '';
	    }
	} else {
	    if ($input =~ /^([^\\"]*)\\(.)(.*)/) {
		$quote .= $1 . $2;
		$input = $3;
	    } elsif ($input =~ /^([^\\"]*)"\s*(.*)/) {
		$name = $quote . $1;
		$input = $2;
		$quote = undef;
	    } else {
		croak "unparsable input $input";
	    }
	}

	if (defined($name)) {
	    $ref->{$name} = {
		-order => $self->{order}++,
		-locus => $locus
	    } unless ref($ref->{$name}) eq 'HASH';
	    $ref = $ref->{$name};
	    
	    if (defined($kw) and ref($kw) eq 'HASH') {
		my $synt;
		if (exists($kw->{$name})) {
		    $synt = $kw->{$name};
		} elsif (exists($kw->{'*'})) {
		    $synt = $kw->{'*'};
		    if ($synt eq '*') {
			$name = undef;
			next;
		    }
		} 
		if (defined($synt)
		    && ref($synt) eq 'HASH'
		    && exists($synt->{section})) {
		    $kw = $synt->{section};
		} else {
		    $kw = undef;
		}
	    } else {
		$kw = undef;
	    }
	    
	    $name = undef;
	}
    }
    return ($ref, $kw);
}

sub check_mandatory {
    my $self = shift;
    my $kw = shift;
    my $section = shift;
    my $loc = shift;
    
    my $err = 0;
    while (my ($k, $d) = each %{$kw}) {
	if (ref($d) eq 'HASH') {	
	    if ($d->{mandatory} && !exists($section->{$k})) {
		$loc = $section->{-locus} if exists($section->{-locus});
		$self->error(exists($d->{section})
			     ? "mandatory section ["
			        . join(' ', @_, $k)
				. "] not present"
		             : "mandatory variable \""
			        . join('.', @_, $k)
			        . "\" not set",
			     locus => $loc);
		$self->{error_count}++;
	    }
	    if (exists($d->{section})) {
		if ($k eq '*') {
		    while (my ($name, $vref) = each %{$section}) {
			next if $name =~ /^-/;
			if (exists($d->{select})
			    && !&{$d->{select}}($vref, @_, $name)) {
			    next;
			} elsif (is_section_ref($vref)) {
			    $self->check_mandatory($d->{section},
						   $vref,
						   $loc,
						   @_, $name);
			}
		    }
		} elsif (exists($section->{$k})
			 && (!exists($d->{select})
			     || &{$d->{select}}($section->{$k}, @_, $k))) {
		    $self->check_mandatory($d->{section},
					   $section->{$k},
					   $loc,
					   @_, $k);
		}
	    }
	}
    }
}

sub readconfig {
    my $self = shift;
    my $file = shift;
    my $conf = shift;
    
    $self->debug(1, "reading file $file");
    open(my $fd, "<", $file)
	or do {
	    $self->error("can't open configuration file $file: $!");
	    $self->{error_count}++;
	    return 0;
        };
    
    my $line;
    my $section = $conf;
    my $kw = $self->{parameters};
    my $include = 0;
    
    while (<$fd>) {
	++$line;
	chomp;
	if (/\\$/) {
	    chop;
	    $_ .= <$fd>;
	    redo;
	}
	
	s/^\s+//;
	s/\s+$//;
	s/#.*//;
	next if ($_ eq "");
	    
	if (/^\[(.+?)\]$/) {
	    $include = 0;
	    my $arg = $1;
	    $arg =~ s/^\s+//;
	    $arg =~ s/\s+$//;
	    if ($arg eq 'include') {
		$include = 1;
	    } else {
		($section, $kw) = $self->parse_section($conf, $1,
						       new App::Glacier::Config::Locus($file, $line));
		if (exists($self->{parameters}) and !defined($kw)) {
		    $self->error("unknown section",
				 locus => $section->{-locus});
			$self->{error_count}++;
		}
	    }
	} elsif (/([\w_-]+)\s*=\s*(.*)/) {
	    my ($k, $v) = ($1, $2);
	    $k = lc($k) if $self->{ci};

	    if ($include) {
		if ($k eq 'path') {
		    $self->readconfig($v, $conf);
		} elsif ($k eq 'pathopt') {
		    $self->readconfig($v, $conf) if -f $v;
		} elsif ($k eq 'glob') {
		    foreach my $file (bsd_glob($v, 0)) {
			$self->readconfig($file, $conf);
		    }
		} else {
		    $self->error("keyword \"$k\" is unknown",
				 locus => new App::Glacier::Config::Locus($file, $line));
		    $self->{error_count}++;
		}
		next;
	    }

	    if (defined($kw)) {
		my $x = $kw->{$k};
		$x = $kw->{'*'} unless defined $x;
		if (!defined($x)) {
		    $self->error("keyword \"$k\" is unknown",
				 locus => new App::Glacier::Config::Locus($file, $line));
		    $self->{error_count}++;
		    next;
		} elsif (ref($x) eq 'HASH') {
		    my $errstr;
		    my $prev_val;
		    if (exists($section->{$k})) {
			$prev_val = $section->{$k};
			$prev_val = $prev_val->{-value}
			    if ref($prev_val) eq 'HASH'
				&& exists($prev_val->{-value});
		    }
		    if (exists($x->{re})) {
			if ($v !~ /$x->{re}/) {
			    $self->error("invalid value for $k",
					 locus => new App::Glacier::Config::Locus($file, $line));
			    $self->{error_count}++;
			    next;
			}
		    }

		    if (exists($x->{check})) {
			if (defined($errstr = &{$x->{check}}(\$v, $prev_val))) {
			    $self->error($errstr,
					 locus => new App::Glacier::Config::Locus($file, $line));
			    $self->{error_count}++;
			    next;
			}
		    }

		    if ($x->{array}) {
			if (!defined($prev_val)) {
			    $v = [ $v ];
			} else {
			    $v = [ @{$prev_val}, $v ];
			}
		    }
		}
	    }

	    $section->{-locus}->add($file, $line);
	    unless (exists($section->{$k})) {
		$section->{$k}{-locus} = new App::Glacier::Config::Locus();
	    }
	    $section->{$k}{-locus}->add($file, $line);
	    $section->{$k}{-order} = $self->{order}++;
	    $section->{$k}{-value} = $v;
        } else {
    	    $self->error("malformed line",
			 locus => new App::Glacier::Config::Locus($file, $line));
	    $self->{error_count}++;
	    next;
	}
    }
    close $fd;
    return $self->{error_count} == 0;
}

sub fixup {
    my $self = shift;
    my $params = shift;
    while (my ($kv, $descr) = each %$params) {
	next unless ref($descr) eq 'HASH';
	if (exists($descr->{section})) {
	    $self->fixup($descr->{section}, @_, $kv);
	} elsif (exists($descr->{default}) && !$self->isset(@_, $kv)) {
	    $self->set(@_, $kv, $descr->{default});
	}
    }
}

sub file_up_to_date {
    my ($self, $file) = @_;
    my $st_conf = stat($self->{filename}) or return 1;
    my $st_file = stat($file)
	or carp "can't stat $file: $!";
    return $st_conf->mtime <= $st_file->mtime;
}

=head2 $cfg->parse()

Parses the configuration file and stores the data in the object.  Returns
true on success and false on failure.  Eventual errors in the configuration
are reported using B<error>.

=cut

sub parse {
    my ($self) = @_;
    my %conf;

    return if exists $self->{conf};
    $self->{error_count} = 0;
    if (exists($self->{cachefile}) and -f $self->{cachefile}) {
	if ($self->file_up_to_date($self->{cachefile})) {
	    my $ref;
	    $self->debug(1, "reading from cache file $self->{cachefile}");
	    eval { $ref = retrieve($self->{cachefile}); };
	    if (defined($ref)) {
		$self->{conf} = $ref;
		$self->{updated} = $self->{rw};
		return 1;
	    } elsif ($@) {
		$self->error("warning: unable to load configuration cache: $@");
	    }
	}
	unlink $self->{cachefile};
    }
    
    $self->debug(1, "parsing $self->{filename}");
    $self->readconfig($self->{filename}, \%conf);
    $self->check_mandatory($self->{parameters}, \%conf);

    if ($self->{error_count} == 0) {
	$self->{conf} = \%conf ;
	$self->{updated} = 1;
	$self->fixup($self->{parameters}) if exists $self->{parameters};
	return 1;
    }
    return 0;
}

sub getref {
    my $self = shift;
    
    return undef unless exists $self->{conf};
    my $ref = $self->{conf};
    for (@_) {
	my $k = $self->{ci} ? lc($_) : $_;
	return undef unless exists $ref->{$k};
	$ref = $ref->{$k};
    }
    return $ref;
}

=head2 $var = $cfg->get(@path);

Returns the value of the configuration variable represented by its
I<path>, or B<undef> if the variable is not set.  The path is a list
of configuration variables leading to the value in question.  For example,
the following statement:

    pidfile = /var/run/x.pid

has the path

    ( 'pidfile' )

The path of the B<pidfile> statement in section B<core>, e.g.:

    [core]
        pidfile = /var/run/x.pid

is

    ( 'core', 'pidfile' )

Similarly, the path of the B<file> setting in the following configuration
file:    

    [item foo]
        file = bar
    
is
    ( 'item', 'foo', 'bar' )
    
=head2 $ret = $cfg->get({ variable => $pathref, return => all | value | locus })

I<$pathref> is a reference to the configuration setting path as described
above.  This invocation is similar to B<get(@{$pathref})>, except that
it returns additional data as controlled by the B<return> keyword.  The
valid values for the B<return> are:

=over 4

=item 'value'

Returns the value of the variable.  The call

    $cfg->get({ variable => \@path, return => 'value' })

is completely equivalent to

    $cfg->get(@path);

=item 'locus'

If B<$cfg> was created with B<locations> enabled, returns the source
location of this configuration setting (see B<App::Glacier::Config::Locus>(3)).

=item 'order'

If B<$cfg> was created with B<locations> enabled, returns the I<ordinal
number> of the statement in the configuration file.  Ordinal numbers are
integers starting from 0 and assigned in ascending order to each statement.    
    
=item 'all'

Returns a reference to a hash with the following keys: B<-value>, B<-locus>.
and B<-order>.
    
The B<$ret{-value}> contains the value of the setting.  The B<$ret{-order}>
contains its ordinal number.  The B<$ret{-locus}> contains a reference to
B<App::Glacier::Config::Locus>(3) describing the source location where the
setting was defined.  It is available only if the B<locations> mode is
enabled.
    
=back

If the B<return> key is absent, the result is the same as for
return => 'all'.    

=cut    

sub get {
    my $self = shift;
    croak "no variable to get" unless @_;
    my $ref;
    my $ctl;
    if (ref($_[0]) eq 'HASH') {
	$ctl = shift;
	croak "too many arguments" if @_;
	croak "no variable to get" unless exists $ctl->{variable};
	$ref = $self->getref(@{$ctl->{variable}});
	if (defined($ref)
	    && exists($ctl->{return})
	    && $ctl->{return} ne 'all') {
	    if (exists($ref->{$ctl->{return}})) {
		$ref = $ref->{$ctl->{return}};
	    } else {
		$ref = undef;
	    }
	} 
    } else {
	$ref = $self->getref(@_);
	if (defined($ref) && exists($ref->{-value})) {
	    $ref = $ref->{-value};
	}
    }
    if (ref($ref) eq 'ARRAY') {
	return @$ref
    } elsif (ref($ref) eq 'HASH') {
	return %$ref;
    }
    return $ref;
}

=head2 $cfg->isset(@path)

Returns true if the configuration variable addressed by B<@path> is
set.    
    
=cut

sub isset {
    my $self = shift;
    return defined $self->getref(@_);
}

sub is_section_ref {
    my ($ref) = @_;
    return ref($ref) eq 'HASH'
	   && !exists($ref->{-value});
}

=head2 $cfg->issection(@path)

Returns true if the configuration section addressed by B<@path> is
set.

=cut

sub issection {
    my $self = shift;
    my $ref = $self->getref(@_);
    return defined($ref) && is_section_ref($ref);
}

=head2 $cfg->isvariable(@path)

Returns true if the configuration variable addressed by B<@path> is
set.

=cut

sub isvariable {
    my $self = shift;
    my $ref = $self->getref(@_);
    return defined($ref) && !is_section_ref($ref);
}

=head2 $cfg->set(@path, $value)

Sets the configuration variable B<@path> to B<$value>.    

=cut

sub set {
    my $self = shift;
    $self->{conf} = {} unless exists $self->{conf};
    my $ref = $self->{conf};
   
    while ($#_ > 1) {
	my $arg = shift;
	$ref->{$arg} = {} unless exists $ref->{$arg};
	$ref = $ref->{$arg};
    }
    $ref->{$_[0]}{-order} = $self->{order}++
	unless exists $ref->{$_[0]}{-order};
    $ref->{$_[0]}{-value} = $_[1];
    $self->{updated} = $self->{rw};
}

=head2 cfg->unset(@path)

Unsets the configuration variable.
    
=cut

sub unset {
    my $self = shift;
    return unless exists $self->{conf};
    my $ref = $self->{conf};
    my @path;
    
    for (@_) {
	return unless exists $ref->{$_};
	push @path, [ $ref, $_ ];
	$ref = $ref->{$_};
    }

    while (1) {
	my $loc = pop @path;
	delete ${$loc->[0]}{$loc->[1]};
	last unless (defined($loc) and keys(%{$loc->[0]}) == 0);
    }
    $self->{updated} = $self->{rw};
}    

=head2 @array = $cfg->names_of(@path)

If B<@path> refers to an existing configuration section, returns a list
of names of variables and subsections defined within that section.  E.g.,
if you have

    [item foo]
       x = 1
    [item bar]
       x = 1
    [item baz]
       y = 2

the call

    $cfg->names_of('item')

will return

    ( 'foo', 'bar', 'baz' )
    
=cut    

sub names_of {
    my $self = shift;
    my $ref = $self->getref(@_);
    return () if !defined($ref) || ref($ref) ne 'HASH';
    return map { /^-/ ? () : $_ } keys %{$ref};
}

#sub each {
#    my $self = shift;
#    return @{[ each %{$self->{conf}} ]};
#}

=head2 @array = $cfg->flatten()

=head2 @array = $cfg->flatten(sort => $sort)    

Returns a I<flattened> representation of the configuration, as a
list of pairs B<[ $path, $value ]>, where B<$path> is a reference
to the variable pathname, and B<$value> is a reference to a hash
containing the following keys:

=over 4

=item B<-value>

The value of the setting.

=item B<-order>

The ordinal number of the setting.    

=item B<-locus>

Location of the setting in the configuration file.  See
B<App::Glacier::Config::Locus>(3).  It is available only if the B<locations>
mode is enabled.

=back

=cut

use constant {
    NO_SORT => 0,
    SORT_NATURAL => 1,
    SORT_PATH => 2
};

=pod

The I<$sort> argument controls the ordering of the entries in the returned
B<@array>.  It is either a code reference suitable to pass to the Perl B<sort>
function, or one of the following constants:

=over 4

=item NO_SORT

Don't sort the array.  Statements will be placed in an apparently random
order.

=item SORT_NATURAL

Preserve relative positions of the statements.  Entries in the array will
be in the same order as they appeared in the configuration file.  This is
the default.

=item SORT_PATH

Sort by pathname.

=back

These constants are not exported by default.  You can either import the
ones you need, or use the B<:sort> keyword to import them all, e.g.:

    use App::Glacier::Config qw(:sort);
    @array = $cfg->flatten(sort => SORT_PATH);
    
=cut

sub flatten {
    my $self = shift;
    local %_ = @_;
    my $sort = delete($_{sort});
    $sort = SORT_NATURAL unless defined($sort);
    my @ar;
    my $i;
    
    croak "unrecognized keyword arguments: ". join(',', keys %_)
	if keys %_;

    push @ar, [ [], $self->{conf} ];
    foreach my $elt (@ar) {
	next if exists $elt->[1]{-value};
	while (my ($kw, $val) = each %{$elt->[1]}) {
	    next if $kw =~ /^-/;
	    push @ar, [ [@{$elt->[0]}, $kw], $val ];
	}
    }

    if (ref($sort) eq 'CODE') {
	$sort = sub { sort $sort @_ };
    } elsif ($sort == SORT_PATH) {
	$sort = sub {
	    sort {
		join('.',@{$a->[0]}) cmp join('.', @{$b->[0]})
	    } @_
	};
    } elsif ($sort == SORT_NATURAL) {
	$sort = sub {
	    sort {
		$a->[1]{-order} <=> $b->[1]{-order} } @_
	};
    } elsif ($sort == NO_SORT) {
	$sort = sub { @_ };
    } else {
	croak "unsupported sort value";
    }
    shift @ar; # toss off first entry
    return &{$sort}(map { exists($_->[1]{-value}) ? $_ : () } @ar);
}       

sub __lint {
    my ($self, $syntax, $vref, @path) = @_;

    $syntax = {} unless ref($syntax) eq 'HASH';
    if (exists($syntax->{section})) {
	return unless is_section_ref($vref);
    } else {
	return if is_section_ref($vref);
    }

    if (exists($syntax->{select}) && !&{$syntax->{select}}($vref, @path)) {
	return;
    }

    if (is_section_ref($vref)) {
	$self->_lint($syntax->{section}, $vref, @path);
    } else {
	my $val = $vref->{-value};
	my %opts = ( locus => $vref->{-locus} );
		     
	if (ref($val) eq 'ARRAY') {
	    if ($syntax->{array}) {
		my @ar;
		foreach my $v (@$val) {
		    if (exists($syntax->{re})) {
			if ($v !~ /$syntax->{re}/) {
			    $self->error("invalid value for $path[-1]", %opts);
			    $self->{error_count}++;
			    next;
			}
		    }
		    if (exists($syntax->{check})) {
			my $errstr = &{$syntax->{check}}(\$v,
							 @ar ? $ar[-1] : undef);
			if (defined($errstr)) {
			    $self->error($errstr, %opts);
			    $self->{error_count}++;
			    next;
			}
		    }
		    push @ar, $v;
		}
		$vref->{-value} = \@ar;
		return;
	    } else {
		$val = pop(@$val);
	    }
	}
	
	if (exists($syntax->{re})) {
	    if ($val !~ /$syntax->{re}/) {
		$self->error("invalid value for $path[-1]", %opts);
		$self->{error_count}++;
		return;
	    }
	}

	if (exists($syntax->{check})) {
	    if (defined(my $errstr = &{$syntax->{check}}(\$val))) {
		$self->error($errstr, %opts);
		$self->{error_count}++;
		return;
	    }
	}

	$vref->{-value} = $val;
    }
}

sub _lint {
    my ($self, $syntab, $conf, @path) = @_;
    
    while (my ($var, $value) = each %$conf) {
	next if $var =~ /^-/;
	if (exists($syntab->{$var})) {
	    $self->__lint($syntab->{$var}, $value, @path, $var);
	} elsif (exists($syntab->{'*'})) {
	    $self->__lint($syntab->{'*'}, $value, @path, $var);
	} elsif (is_section_ref($value)) {
	    next;
	} else {
	    $self->error("keyword \"$var\" is unknown",
			 locus => $value->{-locus});
	}
    }
}

=head2 $cfg->lint(\%synt)

Checks the syntax according to the syntax table B<%synt>.  On success,
applies eventual default values and returns true.  On errors, reports
them using B<error> and returns false.

This method provides a way to delay syntax checking for a later time,
which is useful, e.g. if some parts of the parser are loaded as modules
after calling B<parse>.    
    
=cut

sub lint {
    my ($self, $synt) = @_;

#    $synt->{'*'} = { section => { '*' => 1 }} ;
    $self->_lint($synt, $self->{conf});
    $self->check_mandatory($synt, $self->{conf});
    return 0 if $self->{error_count};
    $self->fixup($synt);
    return $self->{error_count} == 0;
}

1;
