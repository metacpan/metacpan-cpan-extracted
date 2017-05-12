use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 5;
}
use DBIx::DBStag;
use FileHandle;

my $moviedata = getmoviedata();
my ($hdr, @data) = process($moviedata);

my $dbhstag = DBIx::DBStag->new;

my $ss = <<EOM
(schema
 (cols
  (col
   (relation "dir")
   (name "lname"))
  (col
   (relation "dir")
   (name "fname"))
  (col
   (relation "dir")
   (name "country"))
  (col
   (relation "movie")
   (name "name"))
  (col
   (relation "movie")
   (name "genre"))
  (col
   (relation "star")
   (name "lname"))
  (col
   (relation "star")
   (name "fname"))
  (col
   (relation "character")
   (name "name")))
 (constraints
  (primarykey
   (relation "movie")
   (col "name"))
  (primarykey
   (relation "dir")
   (col "lname")
   (col "fname")))
 (aliases
  (alias
   (name "dir")
   (table "person")))
 (top "mset")
 (nesting
  (movie
   (dir 1)
   (character
    (star 1)))))
EOM
;
my $mstruct =
  $dbhstag->normalize($ss, \@data);
print $mstruct->xml;
my @movies = $mstruct->where('movie',
                             sub {
                                 grep { 
                                     $_->sgetnode_person->sget_lname eq 'coen'
                                 } shift->getnode_dir
                             });
ok(@movies == 1);
my $movie = shift @movies;
ok($movie->sget_name eq 'barton fink');
my @characters = $movie->get_character;
ok(@characters == 2);

my $schema = Data::Stag->from('sxprstr', $ss);
my $astruct = $schema->sgetnode_aliases;
$astruct->addnode_alias(Data::Stag->new(alias=>[
                                                [name=>'movie'],
                                                [table=>'work']]));
print $schema->sxpr;
my $dirstruct =
  $dbhstag->normalize(-schema=>$schema, 
                      -rows=>\@data,
                      -top=>"dirset",
                      -aliaspolicy=>'n',
                      -nesting=>"'(dirset(dir(movie(star(character 1)))))");

print $dirstruct->sxpr, "\n";
my @dirs = $dirstruct->getnode_dir;
ok(@dirs == 6);
my @coens = grep {$_->sgetnode_person->sget_lname eq 'coen'} @dirs;
ok(@coens == 2);

exit 0;

#

sub process{
    my $data = shift;
    my @data = map {chomp;[split(/\,\s*/, $_)]} split(/\n/,$data);
    # first line is header line
    my $hdr = shift @data;
    $hdr->[0] =~ s/^\#//;
    return ($hdr, @data);
}

sub getmoviedata {

return <<EOM
#director.lname, director.fname, dir.country, film.name, film.genre, actor.lname, actor.fname, character.name
lucas, george, US, star wars, sci-fi, ford, harrison, han solo
lucas, george, US, star wars, sci-fi, fisher, carrie, princess leia
lucas, george, US, star wars, sci-fi, hamill, mark, luke skywalker
lucas, george, US, star wars, sci-fi, earl-jones, james, darth vader
lucas, george, US, star wars, sci-fi, prowse, david, darth vader
lucas, george, US, star wars, sci-fi, guiness, alec, obi-wan kenobi
lucas, george, US, attack of the clones, sci-fi, mcgregor, ewan, obi-wan kenobi
lucas, george, US, attack of the clones, sci-fi, portman, natalie, princess amigdala
jackson, peter, new zealand, braindead, horror, -, -, -, -
jackson, peter, new zealand, lord of the rings, fantasy, lee, christopher, saruman
jackson, peter, new zealand, lord of the rings, fantasy, kellan, ian, gandalf
kurosawa, akira, japan, seven samurai, samurai, mifune, toshiro, Kikuchiyo
cameron, john, US, terminator, sci-fi, schwarzenegger, arnold, terminator
cameron, john, US, terminator2, sci-fi, schwarzenegger, arnold, terminator
coen, joel, US, barton fink, odd, turturro, john, barton fink
coen, ethan, US, barton fink, odd, turturro, john, barton fink
coen, joel, US, barton fink, odd, goodman, john, charlie meadows
coen, ethan, US, barton fink, odd, goodman, john, charlie meadows
EOM
}

sub getcharacterdata {
    return <<EOM
gandalf, goody, staff
luke skywalker, goody, lightsaber
darth vader, baddy, lightsaber
EOM
}

sub getanimaldata {
    return <<EOM
#rel.t, rel.subj, rel.obj
isa, dog, mammal
isa, cat, mammal
isa, mammal, animal
isa, zebra, horse
isa, horse, mammal
isa, unicorn, horse
isa, unicorn, imaginary-animal
instance-of, rover, dog
instance-of, whiskers, cat
instance-of, spot, dog
parent-of, spot, rover
EOM
}
