namespace perl Tappy

typedef i32 account_id

typedef string username

typedef string password

struct account {
	1: account_id id,
	2: i32        allocation
}

exception insufficientResources {
	1: i16    code,
	2: string message
}

exception genericCode {
	1: i16    code,
	2: string message
}

service Accounts {
	account createAccount (
		1: username username,
		2: string   password
	)
	throws (
		1: insufficientResources insufficient,
		2: genericCode code
	),

	account getAccount (
		1: username username
	)
	throws (
		1: genericCode code
	)
}
