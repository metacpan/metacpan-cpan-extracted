package DebugDump;

use vars qw($VERSION);
$VERSION=1.1;

sub debug_dump($;$);
sub debug_dump($;$)
{
    my $ref = shift;
    my $indent = shift || '';
    my $out = '';
    my $type = ref $ref;
    if(not $type) {
        if(defined $ref) {
            $out .= $indent."'$ref'\n";
        }
        else {
            $out .= $indent."undef\n";
        }
    }
    elsif($type eq 'SCALAR' ) {
        $out .= $indent."-> $$ref\n";
    }
    elsif($type eq 'ARRAY' ) {
        $out .= $indent."[\n";
        foreach my $e (@$ref) {
            $out .= debug_dump($e, $indent.'    ');
        }
        $out .= $indent."]\n";
    }
    elsif($type eq 'HASH' ) {
        $out .= $indent."{\n";
        foreach my $k (sort keys %$ref) {
            $out .= $indent."  $k =>\n";
            $out .= debug_dump($ref->{$k}, $indent.'    ');
        }
        $out .= $indent."}\n";
    }
    else {
        $out .= $indent.$type."\n";
    }
    return $out;
}

1;

# vi: sw=4 et
