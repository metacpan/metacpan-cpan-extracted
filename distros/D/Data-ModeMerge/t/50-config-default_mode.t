#!perl

use strict;
use warnings;
use Test::More tests => 19;

use lib './t';
do 'testlib.pm';

use Data::ModeMerge;

mmerge_is(1         , 2        , {default_mode=>'ADD'     }, 3        , 'default_mode ADD (scalar)'     );
mmerge_is([1,2,3]   , [2]      , {default_mode=>'ADD'     }, [1,2,3,2], 'default_mode ADD (array)'      );
mmerge_is({a=>5}    , {a=>2}   , {default_mode=>'ADD'     }, {a=>7}   , 'default_mode ADD (hash)'       );
mmerge_is({a=>5}    , {"*a"=>2}, {default_mode=>'ADD'     }, {"*a"=>2}, 'default_mode ADD (hash) N'     );

mmerge_is(1         , 2        , {default_mode=>'CONCAT'  }, 12       , 'default_mode CONCAT (scalar)'  );
mmerge_is([1,2,3]   , [2]      , {default_mode=>'CONCAT'  }, [1,2,3,2], 'default_mode CONCAT (array)'   );
mmerge_is({a=>5}    , {a=>2}   , {default_mode=>'CONCAT'  }, {a=>52}  , 'default_mode CONCAT (hash)'    );
mmerge_is({a=>5}    , {"*a"=>2}, {default_mode=>'CONCAT'  }, {"*a"=>2}, 'default_mode CONCAT (hash) N'  );

mmerge_is(1         , 2        , {default_mode=>'DELETE'  }, undef    , 'default_mode DELETE (scalar)'  );
mmerge_is([1,2,3]   , [2]      , {default_mode=>'DELETE'  }, undef    , 'default_mode DELETE (array)'   );
mmerge_is({a=>5}    , {a=>2}   , {default_mode=>'DELETE'  }, undef    , 'default_mode DELETE (hash)'    );

mmerge_is(1         , 2        , {default_mode=>'KEEP'    }, 1        , 'default_mode KEEP (scalar)'    );
mmerge_is([1,2,3]   , [2]      , {default_mode=>'KEEP'    }, [1,2,3]  , 'default_mode KEEP (array)'     );
mmerge_is({a=>5}    , {a=>2}   , {default_mode=>'KEEP'    }, {a=>5}   , 'default_mode KEEP (hash)'      );
mmerge_is({"*a"=>5} , {a=>2}   , {default_mode=>'KEEP'    }, {a=>2}   , 'default_mode KEEP (hash) N'    );
mmerge_is({"*a"=>5} , {"+a"=>2}, {default_mode=>'KEEP'    }, {"*a"=>7}, 'default_mode KEEP (hash) N+A'  );

mmerge_is(1         , 2        , {default_mode=>'SUBTRACT'}, -1       , 'default_mode SUBTRACT (scalar)');
mmerge_is([1,2,3]   , [2]      , {default_mode=>'SUBTRACT'}, [1,3]    , 'default_mode SUBTRACT (array)' );
mmerge_is({a=>5}    , {a=>2}   , {default_mode=>'SUBTRACT'}, {}       , 'default_mode SUBTRACT (hash)'  );

