# Tests for DateTime::Calendar::Liturgical::Christian      -*- cperl -*-
#
# This program is free software; you may distribute it under the same
# conditions as Perl itself.
#
# Copyright (c) 2006 Thomas Thurman <thomas@thurman.org.uk>

use Test::More tests => 3 + 365*3;
use strict;
use warnings;
use DateTime;
use DateTime::Calendar::Liturgical::Christian;

ok (1, "loaded DateTime::Calendar::Liturgical::Christian");

while (<DATA>) {
    s/#.*$//;
    chomp;
    next if $_ eq '';
    my $name = substr($_, 33);
    $_ = substr($_, 0, 32);
    my ($date, $colour, $season) = split;

    my ($y, $m, $d) = split(/-/, $date);

    my $dt = DateTime::Calendar::Liturgical::Christian->new(
        year => $y,
        month => $m,
        day => $d,
        tradition => 'ECUSA',
        bvm_blue => 1,
        advent_blue => 1,
        rose => 1,
    );

    is($dt->colour(), $colour, "$date colour");
    is($dt->name(),   $name,   "$date name");
    is($dt->season(), $season, "$date season");
}

my $dt = DateTime->new(day=>4, month=>6, year=>2006); # which was Pentecost

my $dtccl = DateTime::Calendar::Liturgical::Christian->from_object($dt);
is($dtccl->name(), 'Pentecost', 'Can convert from DateTime');

$dtccl = DateTime::Calendar::Liturgical::Christian->new(
    day=>4,
    month=>6,
    year=>2006);

$dt = DateTime->from_object(object=>$dtccl);

is($dt->iso8601(), '2006-06-03T00:00:00', 'Can convert to DateTime');

__DATA__
2006-01-01      white  Christmas Holy Name
2006-01-02      green  Christmas 
2006-01-03      green  Christmas 
2006-01-04      green  Christmas 
2006-01-05      green  Christmas 
2006-01-06      white   Epiphany Epiphany
2006-01-07      green   Epiphany 
2006-01-08      green   Epiphany Epiphany 1
2006-01-09      green   Epiphany 
2006-01-10      white   Epiphany William Laud
2006-01-11      green   Epiphany 
2006-01-12      green   Epiphany 
2006-01-13      white   Epiphany Hilary
2006-01-14      green   Epiphany 
2006-01-15      green   Epiphany Epiphany 2
2006-01-16      green   Epiphany 
2006-01-17      white   Epiphany Antony
2006-01-18      white   Epiphany Confession of Saint Peter
2006-01-19      white   Epiphany Wulfstan
2006-01-20      white   Epiphany Fabian
2006-01-21      white   Epiphany Agnes
2006-01-22      green   Epiphany Epiphany 3
2006-01-23      white   Epiphany Phillips Brooks
2006-01-24      green   Epiphany 
2006-01-25      white   Epiphany Conversion of Saint Paul
2006-01-26      white   Epiphany Timothy and Titus
2006-01-27      white   Epiphany John Chrysostom
2006-01-28      white   Epiphany Thomas Aquinas
2006-01-29      green   Epiphany Epiphany 4
2006-01-30      green   Epiphany 
2006-01-31      green   Epiphany 
2006-02-01      green   Epiphany 
2006-02-02      white   Epiphany Presentation of our Lord
2006-02-03      white   Epiphany Anskar
2006-02-04      white   Epiphany Cornelius
2006-02-05      green   Epiphany Epiphany 5
2006-02-06        red   Epiphany Martyrs of Japan (transferred)
2006-02-07      green   Epiphany 
2006-02-08      green   Epiphany 
2006-02-09      green   Epiphany 
2006-02-10      green   Epiphany 
2006-02-11      green   Epiphany 
2006-02-12      green   Epiphany Epiphany 6
2006-02-13      white   Epiphany Absalom Jones
2006-02-14      white   Epiphany Cyril and Methodius
2006-02-15      white   Epiphany Thomas Bray
2006-02-16      green   Epiphany 
2006-02-17      green   Epiphany 
2006-02-18      green   Epiphany 
2006-02-19      green   Epiphany Epiphany 7
2006-02-20      green   Epiphany 
2006-02-21      green   Epiphany 
2006-02-22      green   Epiphany 
2006-02-23        red   Epiphany Polycarp
2006-02-24      white   Epiphany Matthias
2006-02-25      green   Epiphany 
2006-02-26      green   Epiphany Epiphany 8
2006-02-27      white   Epiphany George Herbert
2006-02-28      white   Epiphany Shrove Tuesday
2006-03-01     purple       Lent Ash Wednesday
2006-03-02      white       Lent Chad
2006-03-03      white       Lent John and Charles Wesley
2006-03-04     purple       Lent 
2006-03-05     purple       Lent Lent 1
2006-03-06     purple       Lent 
2006-03-07        red       Lent Perpetua and her companions
2006-03-08      white       Lent Gregory of Nyssa
2006-03-09      white       Lent Gregory the Great
2006-03-10     purple       Lent 
2006-03-11     purple       Lent 
2006-03-12     purple       Lent Lent 2
2006-03-13     purple       Lent 
2006-03-14     purple       Lent 
2006-03-15     purple       Lent 
2006-03-16     purple       Lent 
2006-03-17      white       Lent Patrick
2006-03-18      white       Lent Cyril
2006-03-19       rose       Lent Lent 3
2006-03-20      white       Lent Joseph (transferred)
2006-03-21      white       Lent Thomas Ken
2006-03-22      white       Lent James De Koven
2006-03-23      white       Lent Gregory the Illuminator
2006-03-24     purple       Lent 
2006-03-25       blue       Lent Annunciation of our Lord
2006-03-26     purple       Lent Lent 4
2006-03-27      white       Lent Charles Henry Brent
2006-03-28     purple       Lent 
2006-03-29      white       Lent John Keble
2006-03-30     purple       Lent 
2006-03-31      white       Lent John Donne
2006-04-01      white       Lent Frederick Denison Maurice
2006-04-02     purple       Lent Lent 5
2006-04-03      white       Lent Richard of Chichester
2006-04-04     purple       Lent 
2006-04-05     purple       Lent 
2006-04-06     purple       Lent 
2006-04-07     purple       Lent 
2006-04-08      white       Lent William Augustus Muhlenberg
2006-04-09     purple       Lent Lent 6
2006-04-10      white       Lent William Law (transferred)
2006-04-11      white       Lent George Augustus Selwyn
2006-04-12     purple       Lent 
2006-04-13     purple       Lent 
2006-04-14     purple       Lent Good Friday
2006-04-15     purple       Lent Easter Eve
2006-04-16      white     Easter Easter
2006-04-17      green     Easter 
2006-04-18      green     Easter 
2006-04-19        red     Easter Alphege
2006-04-20      green     Easter 
2006-04-21      white     Easter Anselm
2006-04-22      green     Easter 
2006-04-23      green     Easter Easter 1
2006-04-24      green     Easter 
2006-04-25      white     Easter Mark the Evangelist
2006-04-26      green     Easter 
2006-04-27      green     Easter 
2006-04-28      green     Easter 
2006-04-29      white     Easter Catherine of Siena
2006-04-30      green     Easter Easter 2
2006-05-01      white     Easter Philip and James
2006-05-02      white     Easter Athanasius
2006-05-03      green     Easter 
2006-05-04      white     Easter Monnica
2006-05-05      green     Easter 
2006-05-06      green     Easter 
2006-05-07      green     Easter Easter 3
2006-05-08      white     Easter Julian of Norwich
2006-05-09      white     Easter Gregory of Nazianzus
2006-05-10      green     Easter 
2006-05-11      green     Easter 
2006-05-12      green     Easter 
2006-05-13      green     Easter 
2006-05-14      green     Easter Easter 4
2006-05-15      green     Easter 
2006-05-16      green     Easter 
2006-05-17      green     Easter 
2006-05-18      green     Easter 
2006-05-19      white     Easter Dustan
2006-05-20      white     Easter Alcuin
2006-05-21      green     Easter Easter 5
2006-05-22      green     Easter 
2006-05-23      green     Easter 
2006-05-24      white     Easter Jackson Kemper
2006-05-25      white     Easter Ascension
2006-05-26      white     Easter Augustine of Canterbury
2006-05-27      green     Easter 
2006-05-28      green     Easter Easter 6
2006-05-29      green     Easter 
2006-05-30      green     Easter 
2006-05-31       blue     Easter Visitation of Mary
2006-06-01      white     Easter Justin
2006-06-02        red     Easter Martyrs of Lyons
2006-06-03        red     Easter Martyrs of Uganda
2006-06-04        red     Easter Pentecost
2006-06-05      white  Pentecost Book of Common Prayer
2006-06-06      white  Pentecost Boniface (transferred)
2006-06-07      green  Pentecost 
2006-06-08      green  Pentecost 
2006-06-09      white  Pentecost Columba
2006-06-10      white  Pentecost Ephrem of Edessa
2006-06-11      white  Pentecost Trinity
2006-06-12      green  Pentecost 
2006-06-13      green  Pentecost 
2006-06-14      white  Pentecost Basil the Great
2006-06-15      green  Pentecost 
2006-06-16      white  Pentecost Joseph Butler
2006-06-17      green  Pentecost 
2006-06-18      green  Pentecost Pentecost 3
2006-06-19      white  Pentecost Bernard Mizeki (transferred)
2006-06-20      green  Pentecost 
2006-06-21      green  Pentecost 
2006-06-22        red  Pentecost Alban
2006-06-23      green  Pentecost 
2006-06-24      white  Pentecost Nativity of John the Baptist
2006-06-25      green  Pentecost Pentecost 4
2006-06-26      green  Pentecost 
2006-06-27      green  Pentecost 
2006-06-28      white  Pentecost Irenaeus
2006-06-29        red  Pentecost Peter and Paul
2006-06-30      green  Pentecost 
2006-07-01      green  Pentecost 
2006-07-02      green  Pentecost Pentecost 5
2006-07-03      green  Pentecost 
2006-07-04      white  Pentecost Independence Day
2006-07-05      green  Pentecost 
2006-07-06      green  Pentecost 
2006-07-07      green  Pentecost 
2006-07-08      green  Pentecost 
2006-07-09      green  Pentecost Pentecost 6
2006-07-10      green  Pentecost 
2006-07-11      white  Pentecost Benedict of Nursia
2006-07-12      green  Pentecost 
2006-07-13      green  Pentecost 
2006-07-14      green  Pentecost 
2006-07-15      green  Pentecost 
2006-07-16      green  Pentecost Pentecost 7
2006-07-17      white  Pentecost William White
2006-07-18      green  Pentecost 
2006-07-19      green  Pentecost 
2006-07-20      green  Pentecost 
2006-07-21      green  Pentecost 
2006-07-22      white  Pentecost Mary Magdalene
2006-07-23      green  Pentecost Pentecost 8
2006-07-24      white  Pentecost Thomas a Kempis
2006-07-25      white  Pentecost James the Apostle
2006-07-26       blue  Pentecost Parents of the Blessed Virgin Mary
2006-07-27      white  Pentecost William Reed Huntington
2006-07-28      green  Pentecost 
2006-07-29      white  Pentecost Mary and Martha
2006-07-30      green  Pentecost Pentecost 9
2006-07-31      white  Pentecost Joseph of Arimathaea
2006-08-01      white  Pentecost Aidan
2006-08-02      green  Pentecost 
2006-08-03      green  Pentecost 
2006-08-04      green  Pentecost 
2006-08-05      green  Pentecost 
2006-08-06      green  Pentecost Pentecost 10
2006-08-07      white  Pentecost Transfiguration (transferred)
2006-08-08      white  Pentecost Dominic
2006-08-09      green  Pentecost 
2006-08-10        red  Pentecost Lawrence
2006-08-11      white  Pentecost Clare
2006-08-12      green  Pentecost 
2006-08-13      green  Pentecost Pentecost 11
2006-08-14      white  Pentecost Jeremy Taylor (transferred)
2006-08-15       blue  Pentecost Mary the Virgin
2006-08-16      green  Pentecost 
2006-08-17      green  Pentecost 
2006-08-18      white  Pentecost William Porcher DuBose
2006-08-19      green  Pentecost 
2006-08-20      green  Pentecost Pentecost 12
2006-08-21      white  Pentecost Bernard (transferred)
2006-08-22      green  Pentecost 
2006-08-23      green  Pentecost 
2006-08-24      white  Pentecost Bartholemew
2006-08-25      white  Pentecost Louis
2006-08-26      green  Pentecost 
2006-08-27      green  Pentecost Pentecost 13
2006-08-28      white  Pentecost Augustine of Hippo
2006-08-29      green  Pentecost 
2006-08-30      green  Pentecost 
2006-08-31      green  Pentecost 
2006-09-01      green  Pentecost 
2006-09-02        red  Pentecost Martyrs of New Guinea
2006-09-03      green  Pentecost Pentecost 14
2006-09-04      green  Pentecost 
2006-09-05      green  Pentecost 
2006-09-06      green  Pentecost 
2006-09-07      green  Pentecost 
2006-09-08      green  Pentecost 
2006-09-09      green  Pentecost 
2006-09-10      green  Pentecost Pentecost 15
2006-09-11      green  Pentecost 
2006-09-12      white  Pentecost John Henry Hobart
2006-09-13      white  Pentecost Cyprian
2006-09-14      white  Pentecost Holy Cross
2006-09-15      green  Pentecost 
2006-09-16      white  Pentecost Ninian
2006-09-17      green  Pentecost Pentecost 16
2006-09-18      white  Pentecost Edward Bouverie Pusey
2006-09-19      white  Pentecost Theodore of Tarsus
2006-09-20        red  Pentecost John Coleridge Patteson and companions
2006-09-21        red  Pentecost Matthew
2006-09-22      green  Pentecost 
2006-09-23      green  Pentecost 
2006-09-24      green  Pentecost Pentecost 17
2006-09-25      white  Pentecost Sergius
2006-09-26      white  Pentecost Lancelot Andrewes
2006-09-27      green  Pentecost 
2006-09-28      green  Pentecost 
2006-09-29      white  Pentecost Michael and All Angels
2006-09-30      white  Pentecost Jerome
2006-10-01      green  Pentecost Pentecost 18
2006-10-02      white  Pentecost Remigius (transferred)
2006-10-03      green  Pentecost 
2006-10-04      white  Pentecost Francis of Assisi
2006-10-05      green  Pentecost 
2006-10-06      white  Pentecost William Tyndale
2006-10-07      green  Pentecost 
2006-10-08      green  Pentecost Pentecost 19
2006-10-09      white  Pentecost Robert Grosseteste
2006-10-10      green  Pentecost 
2006-10-11      green  Pentecost 
2006-10-12      green  Pentecost 
2006-10-13      green  Pentecost 
2006-10-14      green  Pentecost 
2006-10-15      green  Pentecost Pentecost 20
2006-10-16        red  Pentecost Hugh Latimer, Nicholas Ridley, Thomas Cranmer
2006-10-17        red  Pentecost Ignatius
2006-10-18      white  Pentecost Luke
2006-10-19      white  Pentecost Henry Martyn
2006-10-20      green  Pentecost 
2006-10-21      green  Pentecost 
2006-10-22      green  Pentecost Pentecost 21
2006-10-23        red  Pentecost James of Jerusalem
2006-10-24      green  Pentecost 
2006-10-25      green  Pentecost 
2006-10-26      white  Pentecost Alfred the Great
2006-10-27      green  Pentecost 
2006-10-28      white  Pentecost Simon and Jude
2006-10-29      green  Pentecost Pentecost 22
2006-10-30        red  Pentecost James Hannington and his companions (transferred)
2006-10-31      green  Pentecost 
2006-11-01      white  Pentecost All Saints
2006-11-02      white  Pentecost All Faithful Departed
2006-11-03      white  Pentecost Richard Hooker
2006-11-04      green  Pentecost 
2006-11-05      green  Pentecost Pentecost 23
2006-11-06      green  Pentecost 
2006-11-07      white  Pentecost Willibrord
2006-11-08      green  Pentecost 
2006-11-09      green  Pentecost 
2006-11-10      white  Pentecost Leo the Great
2006-11-11      white  Pentecost Martin of Tours
2006-11-12      green  Pentecost Pentecost 24
2006-11-13      white  Pentecost Charles Simeon (transferred)
2006-11-14      white  Pentecost Consecration of Samuel Seabury
2006-11-15      green  Pentecost 
2006-11-16      white  Pentecost Margaret
2006-11-17      white  Pentecost Hugh
2006-11-18      white  Pentecost Hilda
2006-11-19      white  Pentecost Christ the King
2006-11-20      white  Pentecost Elizabeth of Hungary (transferred)
2006-11-21      green  Pentecost 
2006-11-22      green  Pentecost 
2006-11-23      white  Pentecost Clement of Rome
2006-11-24      green  Pentecost 
2006-11-25      green  Pentecost 
2006-11-26      white     Advent Advent Sunday
2006-11-27       blue     Advent 
2006-11-28       blue     Advent 
2006-11-29       blue     Advent 
2006-11-30      white     Advent Andrew
2006-12-01      white     Advent Nicholas Ferrar
2006-12-02      white     Advent Channing Moore Williams
2006-12-03       rose     Advent Advent 2
2006-12-04      white     Advent John of Damascus
2006-12-05      white     Advent Clement of Alexandria
2006-12-06      white     Advent Nicholas
2006-12-07      white     Advent Ambrose
2006-12-08       blue     Advent 
2006-12-09       blue     Advent 
2006-12-10       blue     Advent Advent 3
2006-12-11       blue     Advent 
2006-12-12       blue     Advent 
2006-12-13       blue     Advent 
2006-12-14       blue     Advent 
2006-12-15       blue     Advent 
2006-12-16       blue     Advent 
2006-12-17       blue     Advent Advent 4
2006-12-18       blue     Advent 
2006-12-19       blue     Advent 
2006-12-20       blue     Advent 
2006-12-21      white     Advent Thomas
2006-12-22       blue     Advent 
2006-12-23       blue     Advent 
2006-12-24       blue     Advent Advent 5
2006-12-25      white  Christmas Christmas
2006-12-26        red  Christmas Stephen
2006-12-27      white  Christmas John the Apostle
2006-12-28        red  Christmas Holy Innocents
2006-12-29      green  Christmas 
2006-12-30      green  Christmas 
2006-12-31      green  Christmas Christmas 1
