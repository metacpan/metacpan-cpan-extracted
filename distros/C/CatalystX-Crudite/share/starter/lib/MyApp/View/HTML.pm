package <% dist_module %>::View::HTML;
use Moose;
use namespace::autoclean;
use Template::Stash;
extends 'CatalystX::Crudite::View::TT';
__PACKAGE__->config_template_view(
    INCLUDE_PATH => [ <% dist_module %>->path_to(qw(root templates)) ],
    PRE_PROCESS  => ['<% dist_file %>_config'],
);
Template::Stash->new->define_vmethod(
    scalar => preview => sub {
        my ($value, $max_length) = @_;
        $value =~ s/\s+/ /g;
        return $value unless defined $max_length;
        return $value if length $value <= $max_length;
        return substr($value, 0, $max_length - 3) . '...';
    }
);
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
