TRUNCATE zipcodes;

INSERT INTO zipcodes (zipcode, latitude, longitude, state, city)
SELECT i.zipcode, i.latitude, i.longitude, i.state, i.city
FROM zipcode_import_us i
	JOIN states s ON i.state=s.state
WHERE i.latitude IS NOT NULL
AND i.longitude IS NOT NULL;

INSERT INTO zipcodes (zipcode, latitude, longitude, state, city)
SELECT i.zipcode, avg(i.latitude), avg(i.longitude), min(i.state), min(i.city)
FROM zipcode_import_ca i
	JOIN states s ON i.state=s.state
WHERE i.latitude IS NOT NULL
AND i.longitude IS NOT NULL
GROUP BY i.zipcode;

TRUNCATE zipcode_import_us;
TRUNCATE zipcode_import_ca;
