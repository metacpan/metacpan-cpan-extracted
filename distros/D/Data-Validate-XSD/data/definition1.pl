root => [
  { name => 'input', type => 'news' },
],

complexTypes => {
  news => [
    { name => 'title',   type => 'string', maxLength => 20 },
    { name => 'content', type => 'string', minLength => 20 },
    { name => 'author',  type => 'token',  maxLength => 40 },
    { name => 'editor',  type => 'token',  minOccurs => 0 },
    { name => 'created', type => 'datetime' },
    { name => 'edited',  type => 'datetime', maxOccurs => 3 },
  ],
},
