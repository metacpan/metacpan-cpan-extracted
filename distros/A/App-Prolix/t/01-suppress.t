
use Test::More;

BEGIN { use_ok("App::Prolix") }

{
    my $p = App::Prolix->new;
    push @{$p->ignore_line}, ("spam");
    is $p->process_line("spam"), undef, "basic line";
    is $p->process_line("not spam"), "not spam", "line needs full match";
}

{
    my $p = App::Prolix->new;
    push @{$p->ignore_substring}, ("spa");
    is $p->process_line("spam"), undef, "substring";
    is $p->process_line("not spim"), "not spim", "substring not matched";
}

{
    my $p = App::Prolix->new;
    $p->import_re("spa+m");
    is $p->process_line("I come form the caaastle of spaaaaaam"), undef, "re";
    is $p->process_line("the spm is great"), "the spm is great", "re no match";
}

{
    my $p = App::Prolix->new;
    $p->import_snippet("s/a/b/");
    is $p->snip_line("aa"), "ba", "simple substitution";
    $p->import_snippet("s/BA/MU/i");
    is $p->snip_line("aa"), "MU", "/i, and snippet lists";
    $p->import_snippet("s{MU}(whew)");
    is $p->snip_line("aa"), "whew", "bracketing";

    $p->clear_all;
    is $p->snip_line("aa"), "aa", "clear_all";

    $p->import_snippet(q"s/\d/$/g");  # math is hard, let's go shopping.
    is $p->snip_line(q"It's $123!"), q(It's $$$$!), "/g";

    $p->clear_all;
    $p->import_snippet(q"s/internationalization/i18n/gi");
    $p->import_snippet(q"s/localization/l10n/gi");
    is $p->snip_line(q"This is a question of localization, " .
            "internationalization, and certainly localization and " .
            "internationalization! Internationalization is as important " .
            "as localization here."),
       q"This is a question of l10n, " .
            "i18n, and certainly l10n and " .
            "i18n! i18n is as important " .
            "as l10n here.",
       "prolix prose and /g";
}

{
    my $p = App::Prolix->new;
    $p->import_re("spa+m");
    push @{$p->ignore_substring}, ("bore");
    $p->import_snippet("s/bb/bo/");

    is $p->process_line("spammy line"), undef;
    is $p->process_line("this is a bore"), undef;
    is $p->process_line("bbre gets through"),
       "bore gets through",
       "snippet takes place after filter";
}

done_testing;
