DROP TABLE IF EXISTS "LogSet" CASCADE;
DROP TABLE IF EXISTS "Log" CASCADE;

DROP TYPE IF EXISTS UserType CASCADE;
CREATE TYPE UserType AS ENUM ('Guest', 'Internal', 'External');

DROP TABLE IF EXISTS "Role" CASCADE;
CREATE TABLE "Role" (
	"Id"            SERIAL PRIMARY KEY NOT NULL,
	"Name"			VARCHAR(255) NOT NULL
);

INSERT INTO "Role" ("Id", "Name") VALUES (1, 'Admin');
INSERT INTO "Role" ("Id", "Name") VALUES (2, 'CSR');
INSERT INTO "Role" ("Id", "Name") VALUES (3, 'User');


DROP TABLE IF EXISTS "User" CASCADE;
CREATE TABLE "User" (
	"Id"            SERIAL PRIMARY KEY NOT NULL,
	"Name"			VARCHAR(255) NOT NULL,
	"Email"         VARCHAR(255) NOT NULL UNIQUE,
	"PasswordSalt"  BYTEA NOT NULL,
	"PasswordHash"  BYTEA NOT NULL,
	"Status"		VARCHAR(64) NOT NULL DEFAULT 'Active',
	"UserType"		UserType[] NULL	
);

DROP TABLE IF EXISTS "UserRole" CASCADE;
CREATE TABLE "UserRole" (
	"UserId" INTEGER NOT NULL REFERENCES "User"("Id"),
	"RoleId" INTEGER NOT NULL REFERENCES "Role"("Id"),
	PRIMARY KEY ("UserId", "RoleId")
);

