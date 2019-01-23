return +{
  'Model::Foo' => {
    -inject => {
      from_class => 'MyApp::Dummy2',
      from_code => undef, # Need to blow away the existing...
    },
  },
};
