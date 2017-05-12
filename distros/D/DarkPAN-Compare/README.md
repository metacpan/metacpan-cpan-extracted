# NAME

DarkPAN::Compare - Compare local Perl packages/versions with your DarkPAN

# SYNOPSIS

    use DarkPAN::Compare;

    my $compare = DarkPAN::Compare->new(
        darkpan_url => 'https://darkpan.mycompany.com'
    );

    # Do analysis
    $compare->run;

    # local modules which are not in your darkpan
    # returns an arrayref of hashes
    my $modules = $compare->extra_modules();  
    for my $m (@$modules) {
        print "$m->{name}: $m->{version}\n";
    }

    # local modules which have different versions than your darkpan
    # returns an arrayref of hashes
    my $modules = $compare->modules_with_version_mismatch(); 
    for my $m (@$modules) {
        print "$m->{name}: $m->{darkpan_version}\t$m->{local_version}\n";
    }

# DESCRIPTION

Learn what Perl packages/versions are different in your environment compared to
whats in your darkpan (pinto or orepan2 or whatever).

This module comes with a handy script as well: [compare\_to\_darkpan](https://metacpan.org/pod/compare_to_darkpan)

# LICENSE

Copyright (C) Eric Johnson.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Eric Johnson <eric.git@iijo.org>
