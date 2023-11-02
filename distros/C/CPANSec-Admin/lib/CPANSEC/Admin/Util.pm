use v5.38;
use builtin qw( trim );
no warnings qw(
    experimental::for_list
    experimental::builtin
);

use Path::Tiny ();

package CPANSEC::Admin::Util {

    sub triage_read ($filepath) {
        $filepath = Path::Tiny::path($filepath) if !ref $filepath;
        my @content;
        foreach my $line ($filepath->lines({chomp => 1})) {
            if ($line =~ s/\A\s*\-\s+//) {
                push $content[-1]->@*, $line;
                next;
            }

            my ($k, @v) = split /\s*:\s*/ => $line;
            my $v = join(':', @v);
            undef $v if $v =~ /\A\s*~\s*\z/;
            if ($k =~ /\Areferences/) {
                $v = [];
            }

            push @content, $k, $v;
        }
        return \@content;
    }

    sub triage_write ($filepath, $data) {
        $filepath = Path::Tiny::path($filepath) if !ref $filepath;
        my @content;
        foreach my ($k, $v) (@$data) {
            if (ref $v) {
                $v = "\n- " . join("\n- ", @$v);
            }
            push @content, join ': ', $k, $v;
        }
        $filepath->spew_utf8(join "\n" => @content);
        return;
    }

    sub prompt ($msg, @options) {
        say $msg;
        my $answer;
        PROMPT: while ($answer = <STDIN>) {
            $answer = trim($answer);
            last PROMPT if !@options;
            foreach my $opt (@options) {
                last PROMPT if $answer eq $opt;
            }
            say 'please pick one of: ' . join ', ' => @options;
        }
        return $answer;
    }
}