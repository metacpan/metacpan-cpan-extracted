use 5.006000;
use ExtUtils::MakeMaker;

# Bump 'Event' up to the top of the requires list. We do this because Coro
# won't build Coro::Event unless Event is already installed.
sub MY::metafile {
  package MY;
  my $self = shift;
  my $out = $self->SUPER::metafile_target(@_);
  $out =~ s/
   ( [^\n]*requires:[^\n]* )
   (.*)
   ( \n[^\n]* Event [^\n]* )
  /$1$3$2/xs;
  $out =~ s/(generated_by:.*?)'/$1 and then some'/;
  return $out;
}


WriteMakefile(
    NAME              => 'Continuity',
    VERSION_FROM      => 'lib/Continuity.pm',
    ABSTRACT_FROM     => 'lib/Continuity.pm',
    AUTHOR            => 'Brock Wilcox <awwaiid@thelackthereof.org>',
    LICENSE           => 'perl',
    PREREQ_PM         => {
      Event           => 0,
      HTTP::Daemon    => 1.36,
      Coro            => 4.37,
      Coro::Event     => 0,
    },
    META_MERGE        => {
        resources => {
            repository => 'https://github.com/awwaiid/continuity',
        },
    },
);
