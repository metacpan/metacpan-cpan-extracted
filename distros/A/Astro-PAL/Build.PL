
use strict;
use warnings;
use File::Spec;
use Module::Build;

my $file = File::Spec->catfile( "lib", "Astro", "PAL.pm" );

my $class = Module::Build->subclass(code => << 'EOF');
    sub compile_c {
        my $self = shift;
        my %exclude = map {$_ => 1} qw[
            erfasrc/src/t_erfa_c.c
            erfasrc/src/erfaversion.c
            palsrc/palVers.c
            palsrc/palTest.c
        ];
        return () if exists $exclude{$_[0]};
        return $self->SUPER::compile_c(@_);
    }
EOF

my $build = $class->new
  (
   module_name => "Astro::PAL",
   abstract_from => $file,
   license => "gpl3",
   author => [
              'Tim Jenness <tjenness@cpan.org>',
             ],
   version_from => $file,
   meta_merge => {
               resources =>  {
                              repository => "git://github.com/timj/perl-Astro-PAL.git",
                              homepage => "http://github.com/timj/perl-Astro-PAL/tree/master",
                             },
                },
   script_files => [ qw/
                         stime
                       /],
   requires => {
                "Pod::Usage" => 0,
                "Getopt::Long" => 0,
               },
   build_requires => {
                      "Test::More" => 0,
                      "Test::Number::Delta" => 1.00,
                     },
   configure_requires => {
                          "Module::Build" => 0.3604, # c_source as array ref
                         },
   c_source => ["src", File::Spec->catdir("erfasrc", "src"), "palsrc"],
   extra_compiler_flags => "-DNOSTARUTIL=1",
  );

$build->create_build_script;

