# NAME

Acme::AtIncPolice - The police that opponents to @INC contamination

# SYNOPSIS

    use Acme::AtIncPolice;
    # be killed by Acme::AtIncPolice
    push @INC, sub {
        my ($coderef, $filename) = @_;
        my $modfile = "lib/$filename";
        if (-f $modfile) {
            open my $fh, '<', $modfile;
            return $fh;
        }
    };
    # be no-op ed by Acme::AtIncPolice
    push @INC, "lib";

# DESCRIPTION

If you use Acme::AtIncPolice, your program be died when detects any reference value from @INC.

## MOTIVE

@INC hooks is one of useful feature in the Perl. It's used inside of some clever modules.

But, @INC hooks provoke confuse in several cases. 

A feature that resolve library path dynamically is needed on your project that is simple web application? Really? 

The answer is "NO".

Let's go on. Acme::AtIncPolice gives clean programming experience to you. Under Acme::AtIncPolice, @INC hooks is prohibited.

If you found a "smelly" program, Let use Acme::AtIncPolice on it.

# LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

ytnobody <ytnobody@gmail.com>
