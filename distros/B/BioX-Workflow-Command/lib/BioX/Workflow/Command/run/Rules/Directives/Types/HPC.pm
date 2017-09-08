package BioX::Workflow::Command::run::Rules::Directives::Types::HPC;

use Moose::Role;
use namespace::autoclean;

has 'HPC' => (
    is      => 'rw',
    isa     => 'HashRef|ArrayRef',
    default => sub { {} }
);

# after 'BUILD' => sub {
#     my $self = shift;
#
#     $self->set_register_types(
#         'HPC',
#         {
#             builder => 'create_hpc_attr',
#             lookup  => ['^HPC$']
#         }
#     );
# };
#
# sub create_hpc_attr {
#     my $self = shift;
#     my $meta = shift;
#     my $k    = shift;
#     my $v    = shift;
#
#     my $hpc_hash = $self->iter_hpc_array;
#     $self->create_HASH_attr($meta, $k, $hpc_hash);
#
#     $meta->add_attribute(
#         $k => (
#             is         => 'rw',
#             lazy_build => 1,
#         )
#     );
# }
#
# ##TODO Transform all of these to hashes
#
# =head3 iter_hpc_array
#
# =cut
#
# sub iter_hpc_array {
#     my $self       = shift;
#     my $hpc_values = shift;
#
#     if ( ref($hpc_values) eq 'HASH' ) {
#         return $hpc_values;
#     }
#
#     my $hpc_hash = {};
#     foreach my $href ( @{$aref} ) {
#         if ( ref($href) eq 'HASH' ) {
#             my @keys = keys %{$href};
#             map { $hpc_hash->{$_} = $href->{$_} } @keys;
#         }
#         else {
#             $self->app_log->warn(
#                 'You seem to be mixing and matching HPC types.');
#             return $hpc_values;
#         }
#     }
#
#     return $hpc_hash;
# }

1;
