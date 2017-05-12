  use inc::Module::Install;
  
  # Define metadata
  name           'Dancer-Template-Haml';
  perl_version '5.005';

  all_from       'lib/Dancer/Template/Haml.pm';
  
  # Specific dependencies
  requires       'Dancer'  => '1.130', 'Text::Haml' => 0;
  
  WriteAll;
