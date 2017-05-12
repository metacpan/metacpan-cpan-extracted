# $Id$
#
# (c) Hilmar Lapp, hlapp at gmx.net, 2002.
# (c) GNF, Genomics Institute of the Novartis Research Foundation, 2002.
#
# You may distribute this module under the same terms as perl itself.
# Refer to the Perl Artistic License (see the license accompanying this
# software package, or see http://www.perl.com/language/misc/Artistic.html)
# for the terms under which you may use, modify, and redistribute this module.
# 
# THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
# MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#

# POD documentation - main docs before the code

=head1 NAME

Bio::DB::BioDB - class creating the adaptor factory for a particular database

=head1 SYNOPSIS

    $dbadp = Bio::DB::BioDB->new(
			            -database => 'biosql',
                        -user     => 'root',
                        -dbname   => 'pog',
                        -host     => 'caldy',
			               -port     => 3306,    # optional
                        -driver   => 'mysql'
	    );


=head1 DESCRIPTION

This object represents a database that is implemented somehow (you
should not care much as long as you can get the object). From the
object you can pull out other adapters, such as the BioSeqAdapter etc.

=head1 CONTACT

    Hilmar Lapp, hlapp at gmx.net

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::DB::BioDB;

use vars qw(@ISA %LOADED);
use strict;

use Bio::Root::Root;
use Bio::Root::IO;
use Bio::DB::SimpleDBContext;
use Scalar::Util qw(blessed);

@ISA = qw(Bio::Root::Root);

my %db_map = ("biosql" => "Bio::DB::BioSQL::",
				  "map"    => "Bio::DB::Map::");

my $default_prefix = "Bio::DB::";
my $initrc_name = ".bioperldb";

my @DBC_MODULES = ("DBAdaptor", "dbadaptor");

BEGIN {
    %LOADED = ();
}

=head2 new

 Title   : new
 Usage   : $db = Bio::DB::BioDB->new(-database => 'biosql');
 Function: Load and instantiate the encapsulating adaptor for the given
           database.

           This module acts as a factory, similar in spirit to
           Bio::SeqIO, but instead of a sequence stream it returns the
           adaptor object for the specified database.

 Example :
 Returns : a Bio::DB::DBAdaptorI implementing object
 Args    : Named parameters. Currently recognized are

             -database    the name of the database for which the
                          encapsulating adaptor is sought (biosql|markerdb)

             -dbcontext   a Bio::DB::DBContextI implementing object

             -initrc      a scalar denoting a file which when
                          evaluated by perl results in a hash
                          reference or an array reference (to an array
                          with an even number of elements)
                          representing the arguments for this method
                          and for creating an instance of
                          Bio::DB::SimpleDBContext. The special value
                          DEFAULT means to use the file .bioperldb in
                          either the current directory or the home
                          directory, in this order.

             -printerror  whether or not the database and statement
                          handles to be created when necessary should
                          print all errors (the adaptor modules will
                          handle errors themselves, too)

           Instead of -dbcontext, you can also pass all parameters
           accepted by Bio::DB::SimpleDBContext::new(), and this
           module will create the context for you and set the
           dbadaptor property to the returned value. Note that if you
           do pass in your own DBContextI object, as a side effect the
           dbadaptor() property will be changed by this method to
           reflect the created adaptor.

           Note also that if using the -initrc argument any separately
           supplied arguments will override and supplement the
           arguments defined in that file.


=cut

sub new {
    my($pkg, @args) = @_;
    
    my $self = $pkg->SUPER::new(@args);

    my ($biodb, $dbc, $prerr, $initrc) = 
        $self->_rearrange([qw(DATABASE 
                              DBCONTEXT
                              PRINTERROR
                              INITRC
                              )
                           ], @args);

    # first check whether we need to read an initialization record
    if ($initrc && ($initrc eq "DEFAULT")) {
        foreach my $dir (".",$ENV{HOME}) {
            $initrc = Bio::Root::IO->catfile($dir,$initrc_name);
            last if -e $initrc;
            # the default behavior is to ignore if the file isn't
            # present in any of the possible locations
            $initrc = undef;
        }
    }
    if ($initrc) {
        eval {
            $initrc = do $initrc;
        };
        $self->throw("error in evaluating '$initrc': $@") if $@;
        $self->throw("unable to read file '$initrc': $!") if $!;
        $self->throw("'$initrc' failed to return an array ref or hash ref")
            unless $initrc || !ref($initrc);
        if (blessed($initrc) && $initrc->isa("Bio::DB::DBContextI")) {
            # we allow this too
            $dbc = $initrc;
            $initrc = undef;
        } else {
            # if necessary convert to array reference
            if (ref($initrc) eq "HASH") {
                $initrc = [%$initrc];
            }
            # append explicitly supplied arguments
            push(@$initrc, @args);
            # build parameter hash while lower-casing all keys; this will
            # also let supplied arguments override those read from file
            my %params = ();
            while (@$initrc) {
                my $key = lc(shift(@$initrc));
                my $val = shift(@$initrc);
                # don't let undefs override values possibly defined in %initrc
                $params{$key} = $val if defined($val);
            }
            # check for our arguments; they may have come through the file
            $biodb = $params{-database} unless $biodb;
            $prerr = $params{-printerror} unless defined($prerr);
            $self->verbose($params{-verbose}) 
                unless defined($self->verbose) || !exists($params{-verbose});
            # restore argument list from consolidated parameter map
            @args = %params;
        }
    }

    # all arguments should be there now
    $self->throw("you must provide the database (schema)") unless $biodb;
    if(exists($db_map{lc($biodb)})) {
	$biodb = $db_map{lc($biodb)};
    } else {
	$biodb = $default_prefix . $biodb . "::";
    }
    my $dbadp_class = $self->_load_dbadaptor($biodb);
    if(! $dbadp_class) {
	$self->throw("fatal: unable to load DBAdaptor for database: $biodb".
		     "{" . join(",", @DBC_MODULES) . "} all failed to load");
    }
    my $mydbc = $dbc || Bio::DB::SimpleDBContext->new(@args);
    my $dbadp = $dbadp_class->new(-dbcontext  => $mydbc, 
                                  -printerror => $prerr,
                                  -verbose    => $self->verbose);
    # store the adaptor in the context
    $mydbc->dbadaptor($dbadp);
    # success - we hope
    return $dbadp;
}

=head2 _load_dbadaptor

 Title   : _load_dbadaptor
 Usage   : $self->_load_dbadaptor("Bio::DB::BioSQL::");
 Function: Loads up (like use) the DBAdaptorI implementing module for a
           database at run time on demand.
 Example : 
 Returns : TRUE on success
 Args    : The prefix of the database implementing modules.

=cut

sub _load_dbadaptor {
    my ($self, $db) = @_;
    my @msgs = ();

    # check if it's successfully been loaded already before
    return $LOADED{$db} if(exists($LOADED{$db}));
    # try all possibilities
    foreach my $dbadp_name (@DBC_MODULES) {
	eval {
	    $self->_load_module($db . $dbadp_name);
	};
	if($@) {
	    push(@msgs, $@);
	} else {
	    $LOADED{$db} = $db . $dbadp_name;
	    last;
	}
    }
    $self->warn("failed to load dbadaptor: " . join("\n", @msgs))
	if ! $LOADED{$db};
    return $LOADED{$db};
}

=head2 add_db_mapping

 Title   : add_db_mapping
 Usage   : $self->add_db_mapping(key, value)
 Function: Adds another package path mapping to the static private hash %db_map.
 Example :  add_db_mapping("FastBioSQL", "Bio::Das::BioSQL::");
 Returns : None
 Args    : key - arbitrary identifier, value - Perl package path ending in "::"

=cut

sub add_db_mapping {
      my ($self, $key, $value) = @_;
      $db_map{lc $key} = $value;
}


1;
