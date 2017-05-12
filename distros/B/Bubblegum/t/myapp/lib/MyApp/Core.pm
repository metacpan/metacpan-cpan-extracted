package MyApp::Core;

use parent 'Bubblegum';

use Bubblegum::Namespace Array     => 'MyApp::Core::Object::Array';
use Bubblegum::Namespace Code      => 'MyApp::Core::Object::Code';
use Bubblegum::Namespace Float     => 'MyApp::Core::Object::Float';
use Bubblegum::Namespace Hash      => 'MyApp::Core::Object::Hash';
use Bubblegum::Namespace Integer   => 'MyApp::Core::Object::Integer';
use Bubblegum::Namespace Number    => 'MyApp::Core::Object::Number';
use Bubblegum::Namespace Scalar    => 'MyApp::Core::Object::Scalar';
use Bubblegum::Namespace String    => 'MyApp::Core::Object::String';
use Bubblegum::Namespace Undef     => 'MyApp::Core::Object::Undef';
use Bubblegum::Namespace Universal => 'MyApp::Core::Object::Universal';

1;
