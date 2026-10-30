use v5.40;
use Affix;
use Affix::Build;
use Affix::Wrap;
use Path::Tiny;
$|++;

# Create a dummy project on disk
my $dir    = Path::Tiny->tempdir;
my $h_file = $dir->child('rpg.h');
my $c_file = $dir->child('rpg.c');

# A header with enums, structs, and functions
$h_file->spew_utf8(<<'HEADER');
#ifndef RPG_H
#define RPG_H

typedef enum {
    WARRIOR,
    MAGE,
    ROGUE
} ClassType;

typedef struct {
    char* name;
    ClassType job;
    int hp;
} Hero;

// Factory function
Hero* create_hero(const char* name, ClassType job);

// Action function
void attack(Hero* h);

// Destructor
void destroy_hero(Hero* h);

#endif
HEADER

# The implementation
$c_file->spew_utf8(<<'SOURCE');
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "rpg.h"

Hero* create_hero(const char* name, ClassType job) {
    Hero* h = malloc(sizeof(Hero));
    h->name = strdup(name);
    h->job = job;
    h->hp = 100;
    return h;
}

void attack(Hero* h) {
    printf("[RPG] %s (Job: %d) attacks for 10 damage!\n", h->name, h->job);
    fflush(stdout);
}

void destroy_hero(Hero* h) {
    if(h) {
        free(h->name);
        free(h);
    }
}
SOURCE

# Compile the library
say 'Compiling library...';
my $builder = Affix::Build->new( name => 'rpg' );
$builder->add($c_file);
my $lib_path = $builder->link;

# Use Affix::Wrap to introspect the header
#    We explicitly select 'Regex' driver to ensure this demo works
#    even if Clang isn't in the user's PATH.
say "Parsing header: $h_file";
my $wrapper = Affix::Wrap->new( project_files => ["$h_file"], driver => 'Regex' );

# Attach symbols to the current package
#    This reads 'rpg.h', learns 'Hero' and 'ClassType', and binds 'create_hero'
$wrapper->wrap( load_library($lib_path) );

# Use the API (No manual 'affix' calls needed!)
# Note: 'WARRIOR' constant was auto-generated from the enum by Affix::Wrap
my $hero_ptr = create_hero( Conan => WARRIOR() );

#    Struct accessors are available via casting, but here we just pass the pointer back
attack($hero_ptr);

# Cleanup using the bound C function
destroy_hero($hero_ptr);
