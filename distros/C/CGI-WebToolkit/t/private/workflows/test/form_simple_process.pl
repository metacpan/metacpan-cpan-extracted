upload('attachment','test');

use Data::Dumper;

return output(1,'ok', '<pre>'.Dumper($wtk->get('uploads')->[-1]).'</pre>');
