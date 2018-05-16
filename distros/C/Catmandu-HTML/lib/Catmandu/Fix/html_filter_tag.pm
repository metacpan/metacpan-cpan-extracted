package Catmandu::Fix::html_filter_tag;

our $VERSION = '0.02';

use Catmandu::Sane;
use Moo;
use Catmandu::Util;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Inlineable';

has tag => (fix_arg => 1);
has group_by => (fix_opt => 1);

sub fix {
    my ($self,$data) = @_;

    return $data unless Catmandu::Util::is_array_ref($data->{html});

    my $tag = $self->tag;
    my $group_by = $self->group_by;


    my @token;
    my $token_rec;

    for (@{$data->{html}}) {
        if ($_->[0] eq 'S' && $_->[1] =~ /^$tag$/) {
            if ($group_by) {
                my $attrs = $_->[2];
                my $key = $attrs->{$group_by};

                next unless defined($key);
                delete $attrs->{$group_by};
                delete $attrs->{'/'}; # delete single tag end

                my $num_of_keys = int(keys %$attrs);

                if ($token_rec->{$key} && $num_of_keys > 0) {
                    $token_rec->{$key} = [ $token_rec->{$key} ]
                                                unless Catmandu::Util::is_array_ref($token_rec->{$key}) ;
                    push @{$token_rec->{$key}} , $attrs;
                }
                else {
                    $token_rec->{$key} = $attrs;
                }
            }
            else {
                push @token , $_;
            }
        }
    }

    if ($group_by) {
        $data->{html} = $token_rec;
    }
    else {
        $data->{html} = \@token
    }

    return $data;
}

1;


__END__

=pod

=head1 NAME

Catmandu::Fix::html_filter_tag - filter html tags

=head1 SYNOPSIS

   # keep only the meta tags information
   html_filter_tag(meta)
   # produces:
   # ---
   # html:
   #   - [S,html,{},[],<html>]
   #   - ...
   #   - [E,html,</html>]

   # group all attributes of the meta tags grouped by name
   html_filter_tag(meta,group_by:name)
   # produces:
   # ---
   # html:
   #  citation_author:
   #   content: Linda M. Scott
   #  citation_doi:
   #   content: 10.1353/asr.0.0023
   #  citation_fulltext_html_url:
   #   content: https://muse.jhu.edu/article/260988
   #  citation_issn:
   #   content: 1534-7311
   # {etc}

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
