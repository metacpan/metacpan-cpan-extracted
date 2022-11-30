package Pod::Elemental::Transformer::TF_Sig;
# ABSTRACT: TensorFlow signatures

use Moose;
extends 'Pod::Elemental::Transformer::List';

use feature qw{ postderef };
use lib 'lib';
use AI::TensorFlow::Libtensorflow::Lib;
use AI::TensorFlow::Libtensorflow::Lib::Types qw(-all);
use Types::Standard qw(Maybe Str Int ArrayRef CodeRef ScalarRef Ref);
use Types::Encodings qw(Bytes);
use Type::Registry qw(t);

use namespace::autoclean;

sub __is_xformable {
  my ($self, $para) = @_;

  return unless $para->isa('Pod::Elemental::Element::Pod5::Region')
         and $para->format_name =~ /^(?:param|returns|signature)$/;

  confess("list regions must be pod (=begin :" . $self->format_name . ")")
    unless $para->is_pod;

  return 1;
}

my %region_types = (
  'signature' => 'Signature',
  'param'     => 'Parameters',
  'returns'   => 'Returns',
);

around _expand_list_paras => sub {
  my ($orig, $self, $para) = @_;

  my $is_list_type = $para->format_name =~ /^(?:param|returns)$/;

  if( $is_list_type ) {
    die "Need description list for @{[ $para->as_pod_string ]}"
      unless $para->children->[0]->content =~ /^=/;
  }
  my $prefix;
  if( $para->isa('Pod::Elemental::Element::Pod5::Region')
    && exists $region_types{$para->format_name}
  ) {
    $prefix = Pod::Elemental::Element::Pod5::Ordinary->new({
      content => "B<@{[ $region_types{$para->format_name} ]}>",
    });
  }

  my @replacements;
  if( $is_list_type ) {
    @replacements = $orig->($self, $para);
  } else {
    undef $prefix;
    push @replacements, Pod::Elemental::Element::Pod5::Ordinary
      ->new( { content => do { my $v = <<EOF; chomp $v; $v } });
=over 2

C<<<
@{[ join("\n", map { $_->content } $para->children->@*) ]}
>>>

=back
EOF
  }

  unshift @replacements, $prefix if defined $prefix;

  @replacements;
};

sub __paras_for_num_marker { die "only support definition lists" }
sub __paras_for_bul_marker { die "only support definition lists" }

around __paras_for_def_marker => sub {
  my ($orig, $self, $rest) = @_;

  my $ffi = AI::TensorFlow::Libtensorflow::Lib->ffi;
  my $type_library = 'AI::TensorFlow::Libtensorflow::Lib::Types';
  my @types = ($rest);
  my $process_type = sub {
    my ($type) = @_;
    my $new_type_text = $type;
    my $info;
    if( eval { $info->{TT} = t($type); 1 }
      || eval { $info->{FFI} = $ffi->type_meta($type); 1 } ) {
      if( $info->{TT} && $info->{TT}->library eq $type_library ) {
        $new_type_text = "L<$type|$type_library/$type>";
      }
    } else {
      die "Could not find type constraint or FFI::Platypus type $type";
    }

    $new_type_text;
  };

  my $type_re = qr{
    \A (?<ws>\s*) (?<type> \w+)
  }xm;
  $rest =~ s[$type_re]{$+{ws} . $process_type->($+{type}) }ge;

  my @replacements = $orig->($self, $rest);

  @replacements;
};

1;
