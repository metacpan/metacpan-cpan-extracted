use Config;
if (my $libs = `pkg-config --libs libssl libcrypto 2>nul`) {
  # strawberry perl has pkg-config
  $self->{LIBS} = [ $libs ];
}
else {
  $self->{LIBS} = ['-lssleay32 -llibeay32'] if $Config{cc} =~ /cl/; # msvc with ActivePerl
  $self->{LIBS} = ['-lssl32 -leay32']       if $Config{gccversion}; # gcc
}
