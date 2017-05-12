{

    package MY;

    use Config;

    sub const_cccmd {
        my $ret = shift->SUPER::const_cccmd(@_);
        return q{} unless $ret;

        if ( $Config{cc} =~ /^cl\b/i ) {
            warn 'you are using MSVC... we may not have gotten some options quite right.';
            $ret .= ' /Fo$@';
        }
        else {
            $ret .= ' -o $@';
        }

        return $ret;
    }

    sub postamble {
        my $txt = <<'EOF';

cover : pure_all
        HARNESS_PERL_SWITCHES=-MDevel::Cover make test

ptest : pure_all
        HARNESS_OPTIONS=j9 make test

EOF
        $txt =~ s/^ +/\t/mg;
        return $txt;
    }

}

