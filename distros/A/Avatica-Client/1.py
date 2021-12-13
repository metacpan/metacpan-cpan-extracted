#!/usr/bin/python3

import logging
import phoenixdb
import phoenixdb.cursor

logging.basicConfig(level=logging.DEBUG)

database_url = 'http://172.17.0.1:8765/'
conn = phoenixdb.connect(database_url, autocommit=True)

cursor = conn.cursor()
# cursor.execute("SELECT * FROM X")
cursor.execute(
    "upsert into Z (A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
    [
        2, 2, 2, 2, 2, 2, 2, 2,
        2.5, 3.5, 4.5, 5.5,
        1234567890.12, False,
        '00:22:10', '2021-11-07', '2021-11-07 00:22:10', '00:22:10', '2021-11-07', '2021-11-07 00:22:10',
        'qwe', 'asd', 'zxc', 'zxcvbnm',
        [1,2,3,4,5]
    ]
)
print(cursor.fetchall())

#cursor = conn.cursor(cursor_factory=phoenixdb.cursor.DictCursor)
#cursor.execute("SELECT * FROM users WHERE id=1")
#print(cursor.fetchone()['USERNAME'])
