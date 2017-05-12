use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'CGI::Inspect',
    VERSION_FROM      => 'lib/CGI/Inspect.pm',
    ABSTRACT_FROM     => 'lib/CGI/Inspect.pm',
    AUTHOR            => 'Brock Wilcox <awwaiid@thelackthereof.org>',
    LICENSE           => 'perl',
    PREREQ_PM         => {
      'Continuity'                                         => '1.01',
      'PadWalker'                                          => 0,
      'Devel::LexAlias'                                    => 0,
      'Devel::StackTrace::WithLexicals'                    => '0.01',
      # 'Coro::Generator'                                    => 0,
      # 'Method::Signatures'                                 => '20081008',
      # 'Moose'                                              => '0.58',
      # 'Moose::Exporter'                                    => 0,
      # 'Module::Refresh'                                    => 0,
    },
);
