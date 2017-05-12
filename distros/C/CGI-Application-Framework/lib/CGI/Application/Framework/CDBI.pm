# ////////////////////
# //////////////////// Beginning of CDBI class, based on Class::DBI
# //////////////////// and Class::DBI::mysql. This class has to provide
# //////////////////// enough info for database connections to be made, along
# //////////////////// with whatever other method overrides, utility methods,
# //////////////////// etc. might be needed or desired by the classes that
# //////////////////// are based on CDBI.
# ////////////////////

package CGI::Application::Framework::CDBI;

use warnings;
use strict;

use vars qw ( @ISA );
use Exporter;


# -------------------------------------------------------------------
# Name of the CAP::CC configuration in which the database info can
# be found
#
# (can be overridden by a subclass)
#
# To use the same configuration file and settings as the main application,
# leave this as the default, which is undefined.
# -------------------------------------------------------------------
sub db_config_name {
    undef;
}

# -------------------------------------------------------------------
# Section within the configuration file in which the database info can
# be found
#
# (should be overridden by a subclass)
#
# For instance, if the database options are in the <database> section,
# return the string 'database'
# -------------------------------------------------------------------
sub db_config_section {
    'db_example';
}


# ------------------------------------------------------------------------
# This idiom copied from the Class::DBI perldoc page on search.cpan.org.
# It is 1/2 of an idiomatic system meant to support transactions. (An
# example of the usage of the second (invocative) half immediately
# follows...
# ------------------------------------------------------------------------
sub do_transaction {

    my $class = shift;
    my ( $code ) = @_;

    # -----------------------------------------------------------
    # Turn off AutoCommit for this scope.
    # A commit will occur at the exit of this block automatically,
    # when the local AutoCommit goes out of scope.
    # -----------------------------------------------------------
    local $class->db_Main->{ AutoCommit };

    # -----------------------------------------------------------
    # Execute the required code inside the transaction.
    # -----------------------------------------------------------
    eval { $code->() };
    # -----------------------------------------------------------
    if ( $@ ) {
	my $commit_error = $@;
	eval { $class->dbi_rollback }; # might also die!
	die $commit_error;
    }
}

# ------------------------------------------------------------------------
# Example of how to set up the idiom for transactions
# ------------------------------------------------------------------------
#
# CDBI::LPI::exam_results::auth_user->do_transaction( sub {
#
#    # Fill this area with code as appropriate to the transaction you
#    # want to do, e.g. ...
#
#    my $artist = Music::Artist->create({ name => 'Pink Floyd' });
#    my $cd = $artist->add_to_cds({
#      title => 'Dark Side Of The Moon',
#      year => 1974,
#    });
#
# });
# ------------------------------------------------------------------------

1; # gotta end a .pm file with a 1, or risk being ostracized...

