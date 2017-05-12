CREATE TABLE users (
  username CHAR(20) NOT NULL,
  password VARCHAR(64) NOT NULL,
  CONSTRAINT pk_users PRIMARY KEY (username)
);

INSERT INTO users VALUES ( 'plain',        'plain'                                    );
INSERT INTO users VALUES ( 'crypt',        'lk9Mh5KHGjAaM'                            );
INSERT INTO users VALUES ( 'md5',          '$1$NRe32ijZ$THIS7aDH.e093oDOGD10M/'       );
INSERT INTO users VALUES ( 'smd5',         '{SMD5}eVWRi45+VqS2Xw4bJPN+SrGfpVg='       );
INSERT INTO users VALUES ( 'sha',          '{SHA}2PRZAyDhNDqRW2OUFwZQqPNdaSY='        );
INSERT INTO users VALUES ( 'sha-1 base64', '4zJ0YGPiLDff9wRf61PVIsC5Nms'              );
INSERT INTO users VALUES ( 'sha-1 hex',    'fc1e1866232bfebfac8a8db8f0225a5166fa1a99' );
