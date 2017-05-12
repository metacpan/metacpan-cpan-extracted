#!/bin/bash

dbigraph.pl --dsn=dbi:Pg:dbname=generic_cart --user=online --pass=shopper --as=png > data/generic.cart.png

echo Wrote ./data/generic.cart.png
