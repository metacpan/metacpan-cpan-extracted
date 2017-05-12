package Bio::Tools::EUtilities::Info::FieldInfo;
our $AUTHORITY = 'cpan:BIOPERLML';
$Bio::Tools::EUtilities::Info::FieldInfo::VERSION = '1.75';
use utf8;
use strict;
use warnings;
use base qw(Bio::Root::Root Bio::Tools::EUtilities::EUtilDataI);

# ABSTRACT: Class for storing einfo field data.
# AUTHOR:   Chris Fields <cjfields@bioperl.org>
# OWNER:    2006-2013 Chris Fields
# LICENSE:  Perl_5



sub new {
    my ($class, @args) = @_;
    my $self = $class->SUPER::new(@args);
    $self->eutil('einfo');
    $self->datatype('fieldinfo');
    return $self;
}


sub get_term_count { return shift->{'_termcount'} }


sub get_field_name { return shift->{'_fullname'} }


*get_full_name = \&get_field_name;


sub get_field_code { return shift->{'_name'} }


sub get_field_description { return shift->{'_description'} }


sub is_date {
    my $self = shift;
    ($self->{'_isdate'} && $self->{'_isdate'} eq 'Y') ? return 1 : return 0;
}


sub is_singletoken {
    my $self = shift;
    ($self->{'_singletoken'} && $self->{'_singletoken'} eq 'Y') ? return 1 : return 0;
}


sub is_hierarchy {
    my $self = shift;
    ($self->{'hierarchy'} && $self->{'hierarchy'} eq 'Y') ? return 1 : return 0;
}


sub is_hidden {
    my $self = shift;
    ($self->{'_ishidden'} && $self->{'_ishidden'} eq 'Y') ? return 1 : return 0;
}


sub is_numerical {
    my $self = shift;
    ($self->{'_isnumerical'} && $self->{'_isnumerical'} eq 'Y') ? return 1 : return 0;
}

# private EUtilDataI method

sub _add_data {
    my ($self, $simple) = @_;
    map { $self->{'_'.lc $_} = $simple->{$_} unless ref $simple->{$_}} keys %$simple;
}


sub to_string {
    my $self = shift;
    #        order     method                     name
    my %tags = (1 => ['get_field_code'        => 'Field Code'],
                2 => ['get_field_name'        => 'Field Name'],
                3 => ['get_field_description' => 'Description'],
                4 => ['get_term_count'        => 'Term Count']);
    my $string;
    for my $tag (sort {$a <=> $b} keys %tags) {
        my ($m, $nm) = ($tags{$tag}->[0], $tags{$tag}->[1]);
        $string .= sprintf("%-20s%s\n", $nm,
            $self->_text_wrap('', ' 'x20 .':', ":".$self->$m));
    }
    $string .= sprintf("%-20s%s\n", "Attributes",
        $self->_text_wrap('', ' 'x20 .':', ":".join(',', grep {$self->$_} qw(is_date
               is_singletoken is_hierarchy is_hidden is_numerical))));
    return $string;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Bio::Tools::EUtilities::Info::FieldInfo - Class for storing einfo field data.

=head1 VERSION

version 1.75

=head1 SYNOPSIS

    #### should not create instance directly; Bio::Tools::EUtilities does this ####

    my $info = Bio::Tools::EUtilities->new(-eutil => 'einfo',
                                           -file => 'einfo.xml');
    # can also use '-response' (for HTTP::Response objects) or '-fh' (for filehandles)

    # print available databases (if data is present)
    print join(', ',$info->get_available_databases),"\n";

    # get database info
    my $db = $info->get_database; # in case you forgot...
    my $desc = $info->get_description;
    my $nm = $info->get_menu_name;
    my $ct = $info->get_record_count;
    my $dt = $info->get_last_update;
    # EUtilDataI interface methods
    my $eutil = $info->eutil;
    my $type = $info->type;

    # iterate through Field and Link objects
    while (my $field = $info->next_Field) {
        print "Field code: ",$field->get_field_code,"\n";
        print "Field name: ",$field->get_field_name,"\n";
        print "Field desc: ",$field->get_field_description,"\n";
        print "DB  : ",$field->get_database,"\n";
        print "Term ct   : ",$field->get_term_count,"\n";
        for my $att (qw(is_date is_singletoken is_hierarchy is_hidden is_numerical)) {
            print "\tField $att\n" if $field->$att;
        }
    }

    my @fields = $info->get_Fields; # grab them all (useful for grep)

    $info->rewind('fields'); # rewinds Field iterator

=head1 DESCRIPTION

This class handles simple field data output (XML) from einfo.

For more information on einfo see:

   http://eutils.ncbi.nlm.nih.gov/entrez/query/static/einfo_help.html

=head2 new

 Title    : new
 Note     : *** should not be called by end-users ***
 Usage    : my $ct = Bio::Tools::EUtilities::Info::FieldInfo;
 Function : returns new FieldInfo instance
 Returns  : Bio::Tools::EUtilities::Info::FieldInfo instance
 Args     : none (all data added via _add_data, most methods are getters only)

=head2 get_term_count

 Title    : get_term_count
 Usage    : my $ct = $field->get_term_count;
 Function : returns number of terms for field
 Returns  : integer
 Args     : none

=head2 get_field_name

 Title    : get_field_name
 Usage    : my $nm = $field->get_field_name;
 Function : returns the full name of the field
 Returns  : string
 Args     : none

=head2 get_full_name

 Title    : get_full_name
 Note     : alias of get_field_name()

=head2 get_field_code

 Title    : get_field_code
 Usage    : $field->get_field_code()
 Function : returns field code (abbreviation) used for queries
 Returns  : string
 Args     : none

=head2 get_field_description

 Title    : get_field_description
 Usage    : $field->get_field_description
 Function : returns field description
 Returns  : string
 Args     : none
 Note     : alias of get_description()

=head2 is_date

 Title    : is_date
 Usage    : if ($field->is_date) {...}
 Function : returns true if field contains date information
 Returns  : Boolean
 Args     : none

=head2 is_singletoken

 Title    : is_singletoken
 Usage    : if ($field->is_singletoken) {...}
 Function : returns true if field has single value in docsums
 Returns  : Boolean
 Args     : none

=head2 is_hierarchy

 Title    : is_hierarchy
 Usage    : if ($field->is_hierarchy) {...}
 Function : returns true if field contains hierarchal values
 Returns  : Boolean
 Args     : none

=head2 is_hidden

 Title    : is_hidden
 Usage    : if ($field->is_hidden) {...}
 Function : returns true if field is hidden in docsums
 Returns  : Boolean
 Args     : none

=head2 is_numerical

 Title    : is_numerical
 Usage    : if ($field->is_numerical) {...}
 Function : returns true if field contains a numerical value
 Returns  : Boolean
 Args     : none

=head2 to_string

 Title    : to_string
 Usage    : $foo->to_string()
 Function : converts current object to string
 Returns  : none
 Args     : (optional) simple data for text formatting
 Note     : Used generally for debugging and for various print methods

=head1 FEEDBACK

=head2 Mailing lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to
the Bioperl mailing list.  Your participation is much appreciated.

  bioperl-l@bioperl.org                  - General discussion
  http://bioperl.org/wiki/Mailing_lists  - About the mailing lists

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

  https://github.com/bioperl/%%7Bdist%7D

=head1 AUTHOR

Chris Fields <cjfields@bioperl.org>

=head1 COPYRIGHT

This software is copyright (c) 2006-2013 by Chris Fields.

This software is available under the same terms as the perl 5 programming language system itself.

=cut
