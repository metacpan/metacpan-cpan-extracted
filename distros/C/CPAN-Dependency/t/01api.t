use strict;
use Test;
BEGIN { plan tests => 39 }
use CPAN::Dependency;

# check that the following functions are available
ok( defined &CPAN::Dependency::new                        );
ok( defined &CPAN::Dependency::process                    );
ok( defined &CPAN::Dependency::skip                       );
ok( defined &CPAN::Dependency::run                        );
ok( defined &CPAN::Dependency::calculate_score            );
ok( defined &CPAN::Dependency::deps_by_dists              );
ok( defined &CPAN::Dependency::score_by_dists             );
ok( defined &CPAN::Dependency::save_deps_tree             );
ok( defined &CPAN::Dependency::load_deps_tree             );
ok( defined &CPAN::Dependency::load_cpants_db             );
ok( defined &CPAN::Dependency::_tree_walk                 );
ok( defined &CPAN::Dependency::_vprint                    );
ok( defined &CPAN::Dependency::clean_build_dir            );
ok( defined &CPAN::Dependency::color                      );
ok( defined &CPAN::Dependency::debug                      );
ok( defined &CPAN::Dependency::verbose                    );
ok( defined &CPAN::Dependency::prefer_bin                 );

# create an object
my $cpandep = undef;
eval { $cpandep = new CPAN::Dependency };
ok( $@, ''                                                );
ok( defined $cpandep                                      );
ok( $cpandep->isa('CPAN::Dependency')                     );
ok( ref $cpandep, 'CPAN::Dependency'                      );

# check that the following object methods are available
ok( ref $cpandep->can('new')                              );
ok( ref $cpandep->can('process')                          );
ok( ref $cpandep->can('skip')                             );
ok( ref $cpandep->can('run')                              );
ok( ref $cpandep->can('calculate_score')                  );
ok( ref $cpandep->can('deps_by_dists')                    );
ok( ref $cpandep->can('score_by_dists')                   );
ok( ref $cpandep->can('save_deps_tree')                   );
ok( ref $cpandep->can('load_deps_tree')                   );
ok( ref $cpandep->can('load_cpants_db')                   );
ok( ref $cpandep->can('_tree_walk')                       );
ok( ref $cpandep->can('_vprint')                          );
ok( ref $cpandep->can('_vprintf')                         );
ok( ref $cpandep->can('clean_build_dir')                  );
ok( ref $cpandep->can('color')                            );
ok( ref $cpandep->can('debug')                            );
ok( ref $cpandep->can('verbose')                          );
ok( ref $cpandep->can('prefer_bin')                       );

