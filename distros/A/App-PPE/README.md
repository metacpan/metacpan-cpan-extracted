[![Build Status](https://travis-ci.org/kfly8/App-PPE.svg?branch=master)](https://travis-ci.org/kfly8/App-PPE)
# NAME

ppe - Prettify Perl Error messages

# SYNOPSIS

    % perl ~/foo.pl 2>&1 | ppe
    foo.pl:5: [WARN] (W) Use of uninitialized value in warn

# DESCRIPTION

[ppe](https://metacpan.org/pod/ppe) is a prettifier for Perl error messages.

When you are writing such as following:

    use strict;
    use warnings;

    my $str;
    warn $str;

This code outputs following result:

<div>
    <div><img src="https://raw.github.com/kfly8/App-PPE/master/img/example-warnings.png"></div>
</div>

When you are writing such as following:

    use strict;
    use warnings;

    sub f {

This code outputs following result:

<div>
    <div><img src="https://raw.github.com/kfly8/App-PPE/master/img/example-critical.png"></div>
</div>

# SEE ALSO

[perldiag](https://metacpan.org/pod/perldiag)
