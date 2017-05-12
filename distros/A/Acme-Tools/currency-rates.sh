#!/bin/bash
#run as cronscript
/usr/bin/perl -MAcme::Tools -e'Acme::Tools::_update_currency_file("/var/www/currency-rates")'
