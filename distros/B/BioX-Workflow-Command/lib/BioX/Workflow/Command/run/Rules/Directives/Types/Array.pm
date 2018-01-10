package BioX::Workflow::Command::run::Rules::Directives::Types::Array;

use Moose::Role;
use namespace::autoclean;

sub create_ARRAY_attr {
    my $self = shift;
    my $meta = shift;
    my $k    = shift;

    $meta->add_attribute(
        $k => (
            traits  => ['Array'],
            isa     => 'ArrayRef',
            is      => 'rw',
            clearer => "clear_$k",
            default => sub { [] },
            handles => {
                "all_$k" . "s" => 'elements',
                "count_$k"     => 'count',
                "has_$k"       => 'count',
                "has_no_$k"    => 'is_empty',
            },
        )
    );
}

sub transform_aoh {
  my $self = shift;
  my $k = shift;
  my $v = shift;
  my $lookup = shift || 'k';

  my @data = map { {$lookup => $_} } @{$v};

  $self->$k(\@data);

}

# no Moose;
no Moose::Role;

1;
