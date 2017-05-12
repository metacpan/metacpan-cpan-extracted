CTM
===

Consultation de Control-M (Enterprise Manager ou Server) 6/7/8 via son SGBD.

### Installation :

```
perl Makefile.PL
make
make test
make install
make clean
```

### Exemples :

ControlM EM :

``` perl
use CTM::ReadEM qw/:all/;

my $session = CTM::ReadEM->new(
    version => 7,
    DBMSType => 'Pg',
    DBMSAddress => '127.0.0.1',
    DBMSPort => 3306,
    DBMSInstance => 'ctmem',
    DBMSUser => 'root',
    DBMSPassword => 'root'
);

$session->connect() || die $session->getError();

my $workOnServices = $session->workOnCurrentBIMServices();

unless (defined ($err = $session->getError())) {
    $workOnServices->keepItemsWithAnd({
        service_name => sub {
            shift =~ /^SVC_HEADER_/
        }
    });
    printf "%s : %s\n", $_->{service_name}, getStatusColorForService($_) for (values %{$workOnServices->getItems()});
} else {
    die $err;
}
```

ControlM Server :

``` perl
use CTM::ReadServer qw/:all/;

my $session = CTM::ReadServer->new(
    version => 7,
    DBMSType => 'Pg',
    DBMSAddress => '127.0.0.1',
    DBMSPort => 3306,
    DBMSInstance => 'ctmserver',
    DBMSUser => 'root',
    DBMSPassword => 'root'
);

# ce module n'est pas exploitable ATM.
```

### Pour toutes autres informations :

``` bash
perldoc CTM # ou CTM::ReadEM/CTM::ReadServer
```

### Sources disponibles sur :

- [CPAN](http://search.cpan.org/dist/CTM)
- [GitHub](http://github.com/le-garff-yoann/CTM)

### Licence :

Voir licence Perl.
