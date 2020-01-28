package Bio::Tools::EUtilities::Link::UrlLink;
$Bio::Tools::EUtilities::Link::UrlLink::VERSION = '1.76';
use utf8;
use base qw(Bio::Root::Root Bio::Tools::EUtilities::EUtilDataI);

# ABSTRACT: Class for EUtils UrlLinks.
# AUTHOR:   Chris Fields <cjfields@bioperl.org>
# OWNER:    2006-2013 Chris Fields
# LICENSE:  Perl_5



sub get_dbfrom { return shift->{'_dbfrom'}; }


sub get_attribute { return shift->{'_attribute'}; }


sub get_icon_url { return shift->{'_iconurl'}; }


sub get_subject_type { return shift->{'_subjecttype'}; }


sub get_url {
    my $self = shift;
    # fix Entrz LinkOut URLS without the full URL
    if ($self->{'_url'} && $self->{'_url'} =~ m{^/}) {
        $self->{'_url'} = 'https://www.ncbi.nih.gov'.$self->{'_url'};
    }
    return $self->{'_url'};
}


sub get_link_name { return shift->{'_linkname'};  }


sub get_provider_name { return shift->{'_provider_name'}; }


sub get_provider_abbr { return shift->{'_provider_nameabbr'}; }


sub get_provider_id { return shift->{'_provider_id'}[0]; }


sub get_provider_icon_url { return shift->{'_provider_iconurl'}; }


sub get_provider_url { return shift->{'_provider_url'}; }

# private method

sub _add_data {
    my ($self, $data) = @_;
    if (exists $data->{Provider}) {
        map {$self->{'_provider_'.lc $_} = $data->{Provider}->{$_};
            } keys %{$data->{Provider}};
        delete $data->{Provider};
    }
    map {$self->{'_'.lc $_} = $data->{$_} if $data->{$_}} keys %$data;
}


sub to_string {
    my $self = shift;
    my $level = shift || 0;
    my $pad = 20 - $level;
    #        order     method                    name
    my %tags = (1 => ['get_link_name'          => 'Link Name'],
                2 => ['get_subject_type'       => 'Subject Type'],
                3 => ['get_dbfrom'             => 'DB From'],
                4 => ['get_attribute'          => 'Attribute'],
                6 => ['get_icon_url'           => 'IconURL'],
                7 => ['get_url'                => 'URL'],
                8 => ['get_provider_name'      => 'Provider'],
                9 => ['get_provider_abbr'      => 'ProvAbbr'],
                10 => ['get_provider_id'       => 'ProvID'],
                11 => ['get_provider_url'      => 'ProvURL'],
                12 => ['get_provider_icon_url' => 'ProvIcon'],
                );
    my $string = '';
    for my $tag (sort {$a <=> $b} keys %tags) {
        my ($m, $nm) = ($tags{$tag}->[0], $tags{$tag}->[1]);
        my $content = $self->$m();
        next unless $content;
        $string .= $self->_text_wrap(
                 sprintf("%-*s%-*s:",$level, '',$pad, $nm,),
                 ' ' x ($pad).':',
                 $content)."\n";
    }
    return $string;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::Tools::EUtilities::Link::UrlLink - Class for EUtils UrlLinks.

=head1 VERSION

version 1.76

=head1 SYNOPSIS

  # ...

=head1 DESCRIPTION

  # ...

=head2 get_dbfrom

 Title    : get_dbfrom
 Usage    :
 Function :
 Returns  :
 Args     :

=head2 get_attribute

 Title    : get_attribute
 Usage    :
 Function :
 Returns  :
 Args     :

=head2 get_icon_url

 Title    : get_icon_url
 Usage    :
 Function :
 Returns  :
 Args     :

=head2 get_subject_type

 Title    :
 Usage    :
 Function :
 Returns  :
 Args     :

=head2 get_url

 Title    : get_url
 Usage    :
 Function :
 Returns  :
 Args     :

=head2 get_link_name

 Title    : get_link_name
 Usage    :
 Function :
 Returns  :
 Args     :

=head2 get_provider_name

 Title    : get_provider_name
 Usage    :
 Function :
 Returns  :
 Args     :

=head2 get_provider_abbr

 Title    : get_provider_abbr
 Usage    :
 Function :
 Returns  :
 Args     :

=head2 get_provider_id

 Title    : get_provider_id
 Usage    :
 Function :
 Returns  :
 Args     :

=head2 get_provider_icon_url

 Title    : get_provider_icon_url
 Usage    :
 Function :
 Returns  :
 Args     :

=head2 get_provider_url

 Title    : get_provider_url
 Usage    :
 Function :
 Returns  :
 Args     :

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
