Acme::CPANAuthors::Brazilian
----------------------------

_Nós somos os autores brasileiros no CPAN!_

_We are brazilian CPAN authors!_

[![Build Status](https://travis-ci.org/garu/Acme-CPANAuthors-Brazilian.svg?branch=master)](https://travis-ci.org/garu/Acme-CPANAuthors-Brazilian)
[![CPAN version](https://badge.fury.io/pl/Acme-CPANAuthors-Brazilian.svg)](http://badge.fury.io/pl/Acme-CPANAuthors-Brazilian)

### Oi? ###

Essa classe é usada para fornecer um hash com id/nome PAUSE de
todos os autores brasileiros no [CPAN](https://metacpan.org) :)

    use Acme::CPANAuthors;
    use Acme::CPANAuthors::Brazilian;

    my $authors = Acme::CPANAuthors->new('Brazilian');

    my $number   = $authors->count;
    my @ids      = $authors->id;
    my @distros  = $authors->distributions('FGLOCK');
    my $url      = $authors->avatar_url('GARU');
    my $kwalitee = $authors->kwalitee('FCO');


### Não achei meu nome! ###

Se você é um autor brasileiro no CPAN e não está listado aqui,
por favor envie seu id/nome via Pull Request no Github, email,
IRC, o que achar melhor, para que possamos manter esse módulo
sempre atualizado. Se houve um erro e você está listado aqui
mas não é brasileiro (ou simplesmente não quer ser listado),
desculpe a inconveniencia: por favor entre em contato que
removeremos a entrada imediatamente.


### Instalação / Installation ###

    cpanm Acme::CPANAuthors::Brazilian

or (manually):

    perl Makefile.PL
    make
    make test
    make install


#### COPYRIGHT AND LICENSE ####

Copyright (C) 2008-2015 Breno G. de Oliveira

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
