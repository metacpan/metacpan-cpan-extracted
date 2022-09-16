package Babble::Plugin::PackageBlock;

use Moo;

sub transform_to_plain {
  my ($self, $top) = @_;
  $top->each_match_within(PackageDeclaration => [
    [ kw => 'package' ],
    [ meta => q{
            (?>(?&PerlNWS)) (?>(?&PerlQualifiedIdentifier))
        (?: (?>(?&PerlNWS)) (?&PerlVersionNumber) )?+
    }],
    [ ws => q{
            (?>(?&PerlOWSOrEND))
    }],
    [ block =>  q{
        (?> (?&PerlBlock) )
    }],
  ] => sub {
    my ($m) = @_;
    my ($kw, $meta,  $ws, $block) = @{$m->submatches}{ qw(kw meta ws block) };

    $kw->replace_text('{ ' . $kw->text);
    $meta->replace_text($meta->text . ';');
    $ws->replace_text('');

    my $block_text = $block->text;
    $block_text =~ s/\A\{//;
    $block->replace_text($block_text);
  });
}

1;
__END__

=head1 NAME

Babble::Plugin::PackageBlock - Plugin for package block syntax

=head1 SYNOPSIS

Converts usage of the package block syntax from

    package NAMESPACE BLOCK

to

    { package NAMESPACE; }

=head1 SEE ALSO

L<package-block syntax|Syntax::Construct/package-block>

=cut
