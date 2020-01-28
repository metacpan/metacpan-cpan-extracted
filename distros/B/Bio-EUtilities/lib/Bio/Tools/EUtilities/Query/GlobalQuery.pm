package Bio::Tools::EUtilities::Query::GlobalQuery;
$Bio::Tools::EUtilities::Query::GlobalQuery::VERSION = '1.76';
use utf8;
use strict;
use warnings;
use base qw(Bio::Root::Root Bio::Tools::EUtilities::EUtilDataI);

# ABSTRACT: Container class for egquery data.
# AUTHOR:   Chris Fields <cjfields@bioperl.org>
# OWNER:    2006-2013 Chris Fields
# LICENSE:  Perl_5


sub new {
    my ($class, @args) = @_;
    my $self = $class->SUPER::new(@args);
    $self->eutil('egquery');
    $self->datatype('globalquery');
    return $self;
}


sub get_term {
    my ($self) = @_;
    return $self->{'_term'};
}


sub get_database {
    my ($self) = @_;
    return $self->{'_dbname'};
}


sub get_count {
    my ($self) = @_;
    return $self->{'_count'};
}


sub get_status {
    my ($self) = @_;
    return $self->{'_status'};
}


sub get_menu_name {
    my $self = shift;
    return $self->{'_menuname'};
}

# private method

sub _add_data {
    my ($self, $data) = @_;
    map {$self->{'_'.lc $_} = $data->{$_}} keys %$data;
}


sub to_string {
    my $self = shift;
    my $string .= sprintf("%-20s Total:%-10d Status:%s\n",
        $self->get_database,
        $self->get_count,
        $self->get_status);
    return $string;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::Tools::EUtilities::Query::GlobalQuery - Container class for egquery data.

=head1 VERSION

version 1.76

=head1 SYNOPSIS

  #### should not create instance directly; Bio::Tools::EUtilities does this ####

  my $parser = Bio::Tools::EUtilities->new(-eutil => 'egquery',
                                           -term  => 'BRCA1');

  # $gquery is a Bio::Tools::EUtilities::Query::GlobalQuery
  while (my $gquery = $parser->next_GlobalQuery) {
     print $gquery->to_string."\n"; # stringify
     print "DB:".$gquery->get_db."\t".$gquery->get_count;
  }

=head1 DESCRIPTION

This is a simple container class for egquery data.  Currently this just contains
various accessors for the data, such as get_database(), get_count(), etc. for
each item in a global query.

=head2 get_term

 Title   : get_term
 Usage   : $st = $qd->get_term;
 Function: retrieve the term for the global search
 Returns : string
 Args    : none

=head2 get_database

 Title   : get_database
 Usage   : $ct = $qd->get_database;
 Function: retrieve the database
 Returns : string
 Args    : none

=head2 get_count

 Title   : get_count
 Usage   : $ct = $qd->get_count;
 Function: retrieve the count for the database
 Returns : string
 Args    : none

=head2 get_status

 Title   : get_status
 Usage   : $st = $qd->get_status;
 Function: retrieve the query status for database in db()
 Returns : string
 Args    : none

=head2 get_menu_name

 Title   : get_menu_name
 Usage   : $ct = $qd->get_menu_name;
 Function: retrieve the full name for the database in db()
 Returns : string
 Args    : None

=head2 to_string

 Title    : to_string
 Usage    : $foo->to_string()
 Function : converts current object to string
 Returns  : none
 Args     : (optional) simple data for text formatting
 Note     : Used generally for debugging and for the print_GlobalQuery method

=head1 FEEDBACK

=head2 Mailing lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to
the Bioperl mailing list.  Your participation is much appreciated.

  bioperl-l@bioperl.org               - General discussion
  https://bioperl.org/Support.html    - About the mailing lists

=head2 Support

Please direct usage questions or support issues to the mailing list:
I<bioperl-l@bioperl.org>
rather than to the module maintainer directly. Many experienced and
reponsive experts will be able look at the problem and quickly
address it. Please include a thorough description of the problem
with code and data examples if at all possible.

=head2 Reporting bugs

Report bugs to the Bioperl bug tracking system to help us keep track
of the bugs and their resolution. Bug reports can be submitted via the
web:

  https://github.com/bioperl/bio-eutilities/issues

=head1 AUTHOR

Chris Fields <cjfields@bioperl.org>

=head1 COPYRIGHT

This software is copyright (c) 2006-2013 by Chris Fields.

This software is available under the same terms as the perl 5 programming language system itself.

=cut
