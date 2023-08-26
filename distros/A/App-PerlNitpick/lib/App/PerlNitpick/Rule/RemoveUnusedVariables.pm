package App::PerlNitpick::Rule::RemoveUnusedVariables;
use Moose;
use PPI::Document;
use Perl::Critic::Document;
use Perl::Critic::Policy::Variables::ProhibitUnusedVariables;

use App::PerlNitpick::PCPWrap;

no Moose;

sub rewrite {
    my ($self, $doc) = @_;

    my $o = App::PerlNitpick::PCPWrap->new('Perl::Critic::Policy::Variables::ProhibitUnusedVariables');

    my @vio = $o->violates(
        undef,
        Perl::Critic::Document->new(-source => $doc)
    );

    for (@vio) {
        my ($msg, $explain, $el) = @$_;
        if ($el->variables == 1) {
            $el->remove;
        } else {
            # TODO: figure out which variables in this multi-variable statement are unused.
        }
    }

    return $doc;
}

1;

__END__

=encoding UTF-8

=head1 ABSTRACT

All variables written in the code must be used.

=cut
