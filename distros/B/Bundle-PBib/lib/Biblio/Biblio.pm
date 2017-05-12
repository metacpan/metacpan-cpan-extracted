# --*-Perl-*--
# $Id: Biblio.pm 13 2004-11-27 08:58:44Z tandler $
#

=head1 NAME

Biblio::Biblio - Interface class for bibliographic databases

=head1 SYNOPSIS

	use Biblio::Biblio;

	my $bib = new Biblio::Biblio('file' => 'sample.bib')
		or die "Can't open bibliographic database!\n";
	my $bib = new Biblio::Biblio(qw(
			class Database
			dbms mysql
			dbhost samplehost
			dbname biblio
			dbuser biblio
			dbpass biblio
			shortcuts_table shortcuts
			)) or die "Can't open bibliographic database!\n";
	
	my $refs = $bib->queryPapers();
	print join(', ', keys(%{$refs})), "\n";

=head1 DESCRIPTION

Class Biblio provides an abstract interface for bibliographic
databases. It also can be used as a factory for a concrete 
database implementation.

Supported database classes are:

=over

=item Biblio::Database

All databases that can be accessed through Perl's DBI module. 
The mapping of database fields can be configured (arguments 
'column-mapping' and 'column-types', see OOo-table.pbib for an 
example).

=item Biblio::File

Several kind of files, such as bibtex, refer, endnote, tib. 
This uses the cool bp package, a Perl Bibliography Package by Dana Jacobsen (dana@acm.org).

=item I<own subclasses>

You can write your own subclass and pass the class name as the 'class' argument.

=back

=cut

package Biblio::Biblio;
use strict;
use warnings;

# for debug:
use Data::Dumper;

BEGIN {
    use vars qw($Revision $VERSION);
	my $major = 1; q$Revision: 13 $ =~ /: (\d+)/; my ($minor) = ($1); $VERSION = "$major." . ($minor<10 ? '0' : '') . $minor;
}

use Carp;
#use Getopt::Long;
#use Text::ParseWords;



# that's cool!
#  if( 0 ) {
#  if (defined $ENV{"PERLDOC"}) {
    #  require Text::ParseWords;
    #  unshift(@ARGV, Text::ParseWords::shellwords($ENV{"PERLDOC"}));
#  }
#  }
#

=head1 METHODS

=over

=cut


=item my $bib = new Biblio::Biblio(I<options>)

Factory method for concrete database implementations.

Supported Options:

=over

=item class

Class name. If one of the options file, dbname, dsn, or dbms is specified, it is set automatically to Bibilio::File or Biblio::Database.
If the class name does not contain a '::' the classname is prefixed with 'Biblio::'.

=item file

Filename in bibtex, refer or any other supported format.

=item dbms

Name of database type, e.g. ODBC or mysql. This is in fact DBI's dbms argument.

=item dbhost

Hostname. Passed to DBI.

=item dbname

Name of the database. Passed to DBI.

=item dbuser, dbpass

User and password. Passed to DBI.

=item dsn

You can directly specify a DSN that is passed to DBI.

=item B<verbose>

Be more verbose and keep the verbose flag within the options.

=item B<quiet>

Be more quite and keep the quiet flag within the options.

=item I<class specific argument>

Depending on the Biblio class used, other arguments can be specified here.

=back

In addition, some arguments can be specified in the environment:

=over

=item 'class' => 'BIBLIO_CLASS'

=item 'file' => 'BIBLIO_FILE'

=item 'dbms' => 'BIBLIO_DBMS'

=item 'dbhost' => 'BIBLIO_HOST'

=item 'dbname' => 'BIBLIO_NAME'

=item 'dbuser' => 'BIBLIO_USER'

=item 'dbpass' => 'BIBLIO_PASS'

=back

=cut

sub new {
#
# open biblio source
#
    my $class = shift; # Just discard it, not used afterwards.
    my %args = (defaultArgs(), environmentArgs(), @_);
    print Dumper \%args if $args{'verbose'} && $args{'verbose'} > 1;
    $class = $args{'class'};
    if( defined $class && $class !~ /::/ ) {
        $class = "Biblio::$class";
    }
    
    # default rules for fining the class
    if( !defined($class) && defined($args{'file'}) ) {
        $class = 'Biblio::File';
    }
    if( !defined($class) && 
            (defined($args{'dbname'}) || 
			 defined($args{'dsn'}) || 
			 defined($args{'dbms'})) ) {
        $class = 'Biblio::Database';
    }
    
    return undef unless $class;
    
    #print ("use $class; \$${class}::VERSION\n");
    my $version = eval("use $class; \$${class}::VERSION");
    unless( defined($version) ) {
        croak "Failed to open module $class\n";
    }
    print STDERR "Using $class version $version\n" if $args{'verbose'};
	
    return new $class(%args);
}

#
#
# configuration
#
#

sub defaultArgs {
	return (
		#  'class' => 'Database',
		#  'dbname' => 'biblio',
		#  'dbuser' => 'biblio',
		#  'dbpass' => 'biblio',
		);
}


sub environmentArgs {
#
# check environment for arguments
#
	my %envargs = (
		'class' => $ENV{'BIBLIO_CLASS'},
		'dbms' => $ENV{'BIBLIO_DBMS'},
		'dbhost' => $ENV{'BIBLIO_HOST'},
		'dbname' => $ENV{'BIBLIO_NAME'},
		'dbuser' => $ENV{'BIBLIO_USER'},
		'dbpass' => $ENV{'BIBLIO_PASS'},
	
		'file' => $ENV{'BIBLIO_FILE'},
		);
	my ($k, $v); while (($k, $v) = each(%envargs)) {
		delete $envargs{$k} unless defined($v)
	}
	return %envargs;
}

1;

__END__

=back

=head1 AUTHOR

Peter Tandler I<pbib@tandlers.de>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2002-2004 P. Tandler

For copyright information please refer to the LICENSE file included in this distribution.

=head1 SEE ALSO

For usage examples, please refer to PBib, e.g.
L<bin\pbib.pl>, L<bin\PBibTk.pl>
