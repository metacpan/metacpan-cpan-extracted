INSERT INTO users (id,username,password,name) VALUES (1, 'dave', 'beer', 'David Precious'), (2, 'bob', 'cider', 'Bob Smith'), (3, 'mark', 'wantscider', 'Update here');
INSERT INTO roles VALUES (1, 'BeerDrinker'), (2, 'Motorcyclist'), (3, 'CiderDrinker');
INSERT INTO user_roles VALUES (1,1), (1,2), (2,3);
