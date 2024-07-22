# DO NOT EDIT! This file is written by perl_setup_dist.
# If needed, you can add content at the end of the file.

requires 'perl', '5.26.0';

on 'configure' => sub {
  requires 'perl', '5.26.0';
  requires 'ExtUtils::MakeMaker::CPANfile', '0.0.9';
};

on 'test' => sub {
  requires 'CPAN::Common::Index::Mux::Ordered';
  requires 'Test::CPANfile';
  requires 'Test::More';
  requires 'Test2::V0';
  requires 'Readonly';
  recommends 'Test::Pod', '1.22';
  suggests 'IPC::Run3';  # Only used for spell-checking which is not included in the distribution
  suggests 'Test2::Tools::PerlCritic';
  suggests 'Perl::Tidy', '20220613';
};

# Develop phase dependencies are usually not installed, this is what we want as
# Devel::Cover has many dependencies.
on 'develop' => sub {
  recommends 'Devel::Cover';
};

# End of the template. You can add custom content below this line.

requires 'Parallel::TaskExecutor';
requires 'Data::Section::Simple';
requires 'IPC::Run';
requires 'Log::Log4perl';
requires 'Log::Any';
requires 'Log::Any::Simple', '0.05';
requires 'Log::Any::Adapter::Log4perl';
requires 'Win32::ShellQuote';
