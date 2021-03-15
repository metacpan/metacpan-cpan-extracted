package App::PerlNitpick::Rule::RemoveEffectlessUTF8Pragma;
# ABSTRACT: Re-quote strings with single quotes ('') if they look "simple"

use Moose;
use PPI::Document;

sub rewrite {
    my ($self, $doc) = @_;

    my $use_utf8_statements = $doc->find(
        sub {
            my $st = $_[1];
            $st->isa('PPI::Statement::Include') && $st->schild(0) eq 'use' && $st->schild(1) eq 'utf8';
        }
    );
    return $doc unless $use_utf8_statements;
    
    my $chars_outside_ascii_range = 0;
    for (my $tok = $doc->first_token; $tok && $chars_outside_ascii_range == 0; $tok = $tok->next_token) {
        next unless $tok->significant;
        my $src = $tok->content;
        utf8::decode($src);

        my $len = length($src);
        for (my $i = 0; $i < $len && $chars_outside_ascii_range == 0; $i++) {
            if (ord(substr($src, $i, 1)) > 127) {
                $chars_outside_ascii_range++;
            }
        }
    }

    unless ($chars_outside_ascii_range) {
        $_->remove for @$use_utf8_statements;
    }

    return $doc;
}

1;
