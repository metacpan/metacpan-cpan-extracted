# NAME

Acme::ReturnValue - report interesting return values

# VERSION

version 1.004

# SYNOPSIS

    use Acme::ReturnValue;
    my $rvs = Acme::ReturnValue->new;
    $rvs->in_INC;
    foreach (@{$rvs->interesting}) {
        say $_->{package} . ' returns ' . $_->{value};
    }

# DESCRIPTION

`Acme::ReturnValue` will list 'interesting' return values of modules.
'Interesting' means something other than '1'.

See [https://returnvalues.plix.at](https://returnvalues.plix.at) for the results of running Acme::ReturnValue on the whole CPAN.

## METHODS

### run

run from the commandline (via `acme_returnvalue.pl`

### waste\_some\_cycles

    my $data = $arv->waste_some_cycles( '/some/module.pm' );

`waste_some_cycles` parses the passed in file using PPI. It tries to
get the last statement and extract it's value.

`waste_some_cycles` returns a hash with following keys

- file

    The file

- package

    The package defintion (the first one encountered in the file

- value

    The return value of that file

`waste_some_cycles` will also put this data structure into
[interesting](https://metacpan.org/pod/interesting) or [boring](https://metacpan.org/pod/boring).

You might want to pack calls to `waste_some_cycles` into an `eval`
because PPI dies on parse errors.

#### \_is\_code

Stolen directly from Perl::Critic::Policy::Modules::RequireEndWithOne
as suggested by Chris Dolan.

Thanks!

### in\_CPAN

Analyse CPAN. Needs a local CPAN mirror

### in\_INC

    $arv->in_INC;

Collect return values from all `*.pm` files in `@INC`.

### in\_dir

    $arv->in_dir( $some_dir );

Collect return values from all `*.pm` files in `$dir`.

### in\_file

    $arv->in_file( $some_file );

Collect return value from the passed in file.

If [waste\_some\_cycles](https://metacpan.org/pod/waste_some_cycles) failed, puts information on the failing file into [failed](https://metacpan.org/pod/failed).

### interesting

Returns an ARRAYREF containing 'interesting' modules.

### boring

Returns an ARRAYREF containing 'boring' modules.

### failed

Returns an ARRAYREF containing unparsable modules.

# BUGS

Probably many, because I'm not sure I master PPI yet.

# AUTHOR

Thomas Klausner <domm@plix.at>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2013 - 2021 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
