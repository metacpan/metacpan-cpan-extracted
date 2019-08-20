package Config::Parser::Ini;
use strict;
use warnings;
use parent 'Config::Parser';
use Carp;
use Text::ParseWords;
    
sub parse {
    my $self = shift;
    $self->{_filename} = shift // confess "No filename given";
    local %_ = @_;
    $self->debug(1, "parsing $self->{_filename}");
    $self->_readconfig($self->{_filename}, %_);
    return $self;
}

sub filename { shift->{_filename} }

# _readconfig(FILE)
sub _readconfig {
    my $self = shift;
    my $file = shift;
    local %_ = @_;
    my $fh = delete $_{fh};
    my $need_close;

    $self->debug(1, "reading file $file");
    unless ($fh) {
	open($fh, "<", $file)
	    or do {
		$self->error("can't open configuration file $file: $!");
		$self->{_error_count}++;
		return 0;
            };
	$need_close = 1;
    }
    
    my $line = delete $_{line} // 0;
    my @path;
    my $include;
    
    while (<$fh>) {
	++$line;
	chomp;
	if (/\\$/) {
	    chop;
	    $_ .= <$fh>;
	    redo;
	}

	s/^\s+//;
	s/\s+$//;
	s/#.*//;
	next if ($_ eq "");
	
	my $locus = new Text::Locus($file, $line);
	
	if (/^\[(.+?)\]$/) {
	    @path = parse_line('\s+', 0, $1);
	    if (@path == 1 && $path[0] eq 'include') {
		$include = 1;
	    } else {
		$include = 0;
		$self->add_node(\@path,
			new Config::AST::Node::Section(locus => $locus)); 
	    }
	} elsif (/([\w_-]+)\s*=\s*(.*)/) {
	    my ($k, $v) = ($1, $2);
	    $k = lc($k) if $self->{_ci}; #FIXME:private member
	    
	    if ($include) {
		if ($k eq 'path') {
		    $self->_readconfig($v);
		} elsif ($k eq 'pathopt') {
		    $self->_readconfig($v) if -f $v;
		} elsif ($k eq 'glob') {
		    foreach my $file (bsd_glob($v, 0)) {
			$self->_readconfig($file);
		    }
		} else {
		    $self->error("keyword \"$k\" is unknown", locus => $locus);
		    $self->{_error_count}++;
		}
	    } else {
		$self->add_value([@path, $k], $v, $locus);
	    }
	} else {
    	    $self->error("malformed line", locus => $locus);
	    $self->{_error_count}++;
	}
    }
    close $fh if $need_close;
}

1;

=head1 NAME

Config::Parser::Ini - configuration file parser for ini-style files

=head1 SYNOPSIS

$cfg = new Config::Parser::Ini($filename);

$val = $cfg->get('dir', 'tmp');

print $val->value;

print $val->locus;

$val = $cfg->tree->Dir->Tmp;

=head1 DESCRIPTION

An I<ini-style configuration file> is a textual file consisting of settings
grouped into one or more sections.  A I<setting> has the form

  KEYWORD = VALUE

where I<KEYWORD> is the setting name and I<VALUE> is its value.
Syntactically, I<VALUE> is anything to the right of the equals sign and up
to the linefeed character terminating the line (ASCII 10), not including
the leading and trailing whitespace characters.

Each setting occupies one line.  Very long lines can be split over several
physical lines by ending each line fragment except the last with a backslash
character appearing right before the linefeed character.

A I<section> begins with a section declaration in the following form:

  [NAME NAME...]

Here, square brackets form part of the syntax.  Any number of I<NAME>s
can be present inside the square brackets.  The first I<NAME> must follow the
usual rules for a valid identifier name.  Rest of I<NAME>s can contain any
characters, provided that any I<NAME> that includes non-alphanumeric characters
is enclosed in a pair of double-quotes.  Any double-quotes and backslash
characters appearing within the quoted string must be escaped by prefixing
them with a single backslash.

The B<Config::Parser::Ini> module is a framework for parsing such files.

In the simplest case, the usage of this module is as simple as in the following
fragment:

  use Config::Parser::Ini;
  my $cf = new Config::Parser::Ini(filename => "config.ini");

On success, this returns a valid B<Config::Parser::Ini> object.  On error,
the diagnostic message is issued using the B<error> method (see the description
of the method in B<Config::AST>(3)) and the module croaks.

This usage, although simple, has one major drawback - no checking is performed
on the input file, except for the syntax check.  To fix this, you can supply
a dictionary (or I<lexicon>) of allowed keywords along with their values.
Such a dictionary is itself a valid ini file, where the value of each
keyword describes its properties.  The dictionary is placed in the B<__DATA__>
section of the source file which invokes the B<Config::Parser::Ini> constructor.

Expanding the example above:

  use Config::Parser::Ini;
  my $cf = new Config::Parser::Ini(filename => "config.ini");

  __DATA__
  [core]
     root = STRING :default /
     umask = OCTAL
  [user]
     uid = NUMBER
     gid = NUMBER

This code specifies that the configuration file can contain at most two
sections: C<[core]> and C<[user]>. Two keywords are defined within each
section.  Data types are specified for each keyword, so the parser will
bail out in case of type mismatches. If the B<core.root> setting is not
present in the configuration, the default one will be created with the
value C</>.

It is often advisable to create a subclass of B<Config::Parser::Ini> and
use it for parsing.  For instance:

  package App::MyConf;
  use Config::Parser::Ini;
  1;
  __DATA__
  [core]
     root = STRING :default /
     umask = OCTAL
  [user]
     uid = NUMBER
     gid = NUMBER

Then, to parse the configuration file, it will suffice to do:

  $cf = my App::MyConf(filename => "config.ini");

One advantage of this approach is that it will allow you to install
additional validation for the configuration statements using the
B<:check> option.  The argument to this option is the name of a
method which will be invoked after parsing the statement in order
to verify its value.  It is described in detail below (see the section
B<SYNTAX DEFINITION> in the documentation of B<Config::Parser>).
For example, if you wish to ensure that the value of the C<root> setting
in C<core> section points to an existing directory, you would do:

  package App::MyConf;
  use Config::Parser::Ini;

  sub dir_exists {
      my ($self, $valref, $prev_value, $locus) = @_;

      unless (-d $$valref) {
          $self->error("$$valref: directory does not exist",
                       locus => $locus);
          return 0;
      }
      return 1;
  }
  1;
  __DATA__
  [core]
     root = STRING :default / :check=dir_exists
     umask = OCTAL
  [user]
     uid = NUMBER
     gid = NUMBER

=head1 CONSTRUCTOR

    $cfg = new Config::Parser::Ini(%opts)

Creates a new parser object.  Keyword arguments are:

=over 4

=item B<filename>

Name of the file to parse.  If not supplied, you will have to
call the B<$cfg-E<gt>parse> method explicitly after you are returned a
valid B<$cfg>.

=item B<line>

Optional line where the configuration starts in B<filename>.  It is used to
keep track of statement location in the file for correct diagnostics.  If
not supplied, B<1> is assumed.

=item B<fh>

File handle to read from.  If it is not supplied, new handle will be
created by using B<open> on the supplied filename.

=item B<lexicon>

Dictionary of allowed configuration statements in the file.  You will not
need this parameter.  It is listed here for completeness sake.  Refer to
the B<Config::AST> constructor for details.

=back

=head1 METHODS

All methods are inferited from B<Config::Parser>.  Please see its
documentation for details.

=head1 SEE ALSO

B<Config::Parser>(3), B<Config::AST>(3).

=cut
