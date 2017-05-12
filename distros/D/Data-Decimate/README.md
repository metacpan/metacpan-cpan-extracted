# perl-Data-Decimate

A module that allows you to decimate or reduce a data feed by selecting the last data in a given interval.
See also https://en.wikipedia.org/wiki/Decimation_(signal_processing) .

#### SYNOPSIS

```
  use Data::Decimate qw(decimate);

  my @data = (
        {epoch  => 1479203101,
        ...},
        {epoch  => 1479203102,
        ...},
        {epoch  => 1479203103,
        ...},
        ...
        {epoch  => 1479203114,
        ...},
        {epoch  => 1479203117,
        ...},
        {epoch  => 1479203118,
        ...},
        ...
  );

  my $output = Data::Decimate::decimate(15, \@data);

  #epoch=1479203114 , decimate_epoch=1479203115
  print $output->[0]->{epoch};
  print $output->[0]->{decimate_epoch};
```

#### INSTALLATION

To install this module, run the following commands:

        perl Makefile.PL
        make
        make test
        make install

#### USAGE

```
    use Data::Decimate;
```

#### SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Data::Decimate

Copyright (C) 2016 binary.com 
