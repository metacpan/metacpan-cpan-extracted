namespace perl Tappy

typedef i32 account_id

// @validate length 1-8
typedef string username

typedef string password

struct account {
	1: account_id id,
	2: i32        allocation
}

i am a bad thrift document

exception insufficientResources {
	1: i16    code,
	2: string message
}

exception genericCode {
	1: i16    code,
	2: string message
}

service Accounts {
	/*
		Create a new account
		@rest POST /accounts
	*/
	account createAccount (
		1: username username,
		2: string   password
	)
	throws (
		1: insufficientResources insufficient,
		2: genericCode code
	),

	/*
		Get an account by username
		@rest GET /account/:username
	*/
	account getAccount (
		1: username username
	)
	throws (
		1: genericCode code
	)
}
